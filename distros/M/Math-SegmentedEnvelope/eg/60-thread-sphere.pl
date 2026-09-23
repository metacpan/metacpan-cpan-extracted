#!/usr/bin/env perl
# Thread sphere: envelope-shaped threads woven around a sphere
# Latitude rings + longitude arcs + diagonal great circles,
# each thread's radius offset controlled by an envelope
#
# Requires: OpenGL::Modern, OpenGL::GLUT, OpenGL::Array
use strict;
use warnings;

BEGIN {
    eval { require OpenGL::Modern; OpenGL::Modern->import(':all'); 1 }
        or die "This example requires OpenGL::Modern\n";
    eval { require OpenGL::GLUT; OpenGL::GLUT->import(':all'); 1 }
        or die "This example requires OpenGL::GLUT\n";
    eval { require OpenGL::Array; 1 }
        or die "This example requires OpenGL::Array\n";
}

use Math::SegmentedEnvelope qw(adsr perc spline env);
use Time::HiRes qw(time);
use POSIX qw(tan floor);

my $W = 900;
my $H = 700;
my $PI = 3.14159265358979323846;

my $sphere_r = 1.2;
my $samples = 100;

# Thread displacement envelopes: control how much each thread lifts off the sphere
my @thread_envs = (
    env([[0, 0.08, 0.15, 0.05, 0], [0.25, 0.25, 0.25, 0.25], [2, -2, 2, -2]],
        morpher_formula => 'smoothstep'),
    spline([0, 0.2, 0.5, 0.8, 1.0], [0, 0.12, 0.04, 0.10, 0]),
    adsr(0.1, 0.2, 0.03, 0.2, peak => 0.15, morpher_formula => 'sine'),
    perc(0.05, 0.95, peak => 0.1, morpher_formula => 'cubic_out'),
    env([[0, 0.06, 0.12, 0.06, 0], [0.25, 0.25, 0.25, 0.25], [3, -3, 3, -3]],
        morpher_formula => 'bounce_out'),
);

my @env_vals;
for my $i (0 .. $#thread_envs) {
    push @env_vals, [$thread_envs[$i]->table($samples)];
}

# Breathing envelope: sphere radius pulses
my $breathe = env([[1.0, 1.06, 1.0], [0.5, 0.5], [2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $breathe_s = $breathe->static;
my $breathe_d = $breathe->duration;

# Thread types
my $lat_rings = 12;     # latitude rings
my $lon_arcs = 12;      # longitude arcs
my $diag_threads = 8;   # diagonal great circles

# Shaders
my $vert_src = <<'GLSL';
#version 150
in vec3 aPos;
in vec4 aColor;
in float aThick;
out VS_OUT { vec4 color; float thick; } vs_out;
uniform mat4 uMVP;
void main() {
    gl_Position = uMVP * vec4(aPos, 1.0);
    vs_out.color = aColor;
    vs_out.thick = aThick;
}
GLSL

my $geom_src = <<'GLSL';
#version 150
layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;
in VS_OUT { vec4 color; float thick; } gs_in[];
out vec4 gColor;
out float gEdge;
uniform vec2 uResolution;

void main() {
    vec4 p0 = gl_in[0].gl_Position;
    vec4 p1 = gl_in[1].gl_Position;
    vec2 d = normalize(p1.xy/p1.w - p0.xy/p0.w);
    vec2 n = vec2(-d.y, d.x);
    float t0 = gs_in[0].thick / uResolution.y;
    float t1 = gs_in[1].thick / uResolution.y;

    gColor = gs_in[0].color; gEdge = -1.0;
    gl_Position = vec4(p0.xy - n*t0*p0.w, p0.zw); EmitVertex();
    gColor = gs_in[0].color; gEdge = 1.0;
    gl_Position = vec4(p0.xy + n*t0*p0.w, p0.zw); EmitVertex();
    gColor = gs_in[1].color; gEdge = -1.0;
    gl_Position = vec4(p1.xy - n*t1*p1.w, p1.zw); EmitVertex();
    gColor = gs_in[1].color; gEdge = 1.0;
    gl_Position = vec4(p1.xy + n*t1*p1.w, p1.zw); EmitVertex();
    EndPrimitive();
}
GLSL

my $frag_src = <<'GLSL';
#version 150
in vec4 gColor;
in float gEdge;
out vec4 outColor;
void main() {
    float d = abs(gEdge);
    float alpha = 1.0 - smoothstep(0.3, 1.0, d);
    float sheen = exp(-d * d * 5.0) * 0.2;
    outColor = vec4(gColor.rgb + sheen, gColor.a * alpha);
}
GLSL

my ($prog, $u_mvp, $u_resolution, $vbo, $vao);
my $start;

sub compile_shader {
    my ($type, $src) = @_;
    my $s = glCreateShader($type);
    glShaderSource_p($s, $src);
    glCompileShader($s);
    my ($ok) = glGetShaderiv_p($s, GL_COMPILE_STATUS);
    die "Shader: " . glGetShaderInfoLog_p($s) unless $ok;
    return $s;
}

sub mat4_perspective {
    my ($fov,$asp,$n,$f) = @_;
    my $t = 1/tan($fov*$PI/360);
    my @m=(0)x16; $m[0]=$t/$asp; $m[5]=$t;
    $m[10]=($f+$n)/($n-$f); $m[11]=-1; $m[14]=2*$f*$n/($n-$f);
    return @m;
}

sub mat4_lookat {
    my($ex,$ey,$ez,$cx,$cy,$cz,$ux,$uy,$uz)=@_;
    my @f=($cx-$ex,$cy-$ey,$cz-$ez);
    my $l=sqrt($f[0]**2+$f[1]**2+$f[2]**2); @f=map{$_/$l}@f;
    my @s=($f[1]*$uz-$f[2]*$uy,$f[2]*$ux-$f[0]*$uz,$f[0]*$uy-$f[1]*$ux);
    $l=sqrt($s[0]**2+$s[1]**2+$s[2]**2); @s=map{$_/$l}@s;
    my @u=($s[1]*$f[2]-$s[2]*$f[1],$s[2]*$f[0]-$s[0]*$f[2],$s[0]*$f[1]-$s[1]*$f[0]);
    return($s[0],$u[0],-$f[0],0,$s[1],$u[1],-$f[1],0,$s[2],$u[2],-$f[2],0,
        -($s[0]*$ex+$s[1]*$ey+$s[2]*$ez),-($u[0]*$ex+$u[1]*$ey+$u[2]*$ez),
        $f[0]*$ex+$f[1]*$ey+$f[2]*$ez,1);
}

sub mat4_mult {
    my($a,$b)=@_;my @r=(0)x16;
    for my $i(0..3){for my $j(0..3){for my $k(0..3){$r[$j*4+$i]+=$a->[$k*4+$i]*$b->[$j*4+$k]}}}
    return @r;
}

sub hsv {
    my ($h,$s,$v)=@_;
    $h=($h-floor($h))*6; my $f=$h-floor($h);
    my $p=$v*(1-$s); my $q=$v*(1-$s*$f); my $t=$v*(1-$s*(1-$f));
    my @c=([$v,$t,$p],[$q,$v,$p],[$p,$v,$t],[$p,$q,$v],[$t,$p,$v],[$v,$p,$q]);
    return @{$c[int($h)%6]};
}

sub fmod { $_[0] - floor($_[0] / $_[1]) * $_[1] }

sub init_gl {
    my $vs = compile_shader(GL_VERTEX_SHADER, $vert_src);
    my $gs = compile_shader(GL_GEOMETRY_SHADER, $geom_src);
    my $fs = compile_shader(GL_FRAGMENT_SHADER, $frag_src);
    $prog = glCreateProgram();
    glAttachShader($prog, $_) for ($vs, $gs, $fs);
    glBindAttribLocation($prog, 0, 'aPos');
    glBindAttribLocation($prog, 1, 'aColor');
    glBindAttribLocation($prog, 2, 'aThick');
    glLinkProgram($prog);
    my ($ok) = glGetProgramiv_p($prog, GL_LINK_STATUS);
    die "Link: ".glGetProgramInfoLog_p($prog) unless $ok;
    glDeleteShader($_) for ($vs, $gs, $fs);
    $u_mvp = glGetUniformLocation($prog, 'uMVP');
    $u_resolution = glGetUniformLocation($prog, 'uResolution');

    ($vao) = glGenVertexArrays_p(1);
    ($vbo) = glGenBuffers_p(1);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_DEPTH_TEST);

    $start = time();
}

sub display {
    my $t = time() - $start;
    my $br = $breathe_s->(fmod($t * 0.5, $breathe_d));
    my $R = $sphere_r * $br;

    glClearColor(0.02, 0.02, 0.05, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    my $cam_a = $t * 0.2;
    my $cam_e = sin($t * 0.13) * 0.4;
    my @proj = mat4_perspective(50, $W/$H, 0.01, 20);
    my @view = mat4_lookat(
        cos($cam_a)*3, 1.0+$cam_e, sin($cam_a)*3,
        0, 0, 0,  0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform2f($u_resolution, $W, $H);

    # per vertex: x,y,z, r,g,b,a, thick = 8 floats
    my @verts;
    my @draw_cmds;  # [offset, count]
    my $total = 0;
    my $thread_id = 0;

    # Latitude rings
    for my $li (1 .. $lat_rings) {
        my $phi = $li / ($lat_rings + 1) * $PI;
        my $ev = $env_vals[$thread_id % @env_vals];
        my $hue = $thread_id / ($lat_rings + $lon_arcs + $diag_threads) + $t * 0.02;
        my $phase = $t * 0.5 + $thread_id * 0.7;

        for my $j (0 .. $samples) {
            my $s = $j / $samples;
            my $theta = $s * 2 * $PI;
            my $lift = $ev->[$j % $samples] * (1 + 0.3 * sin($phase + $s * 4));
            my $r = ($R + $lift) * sin($phi);
            my $y = ($R + $lift) * cos($phi);
            my $x = cos($theta) * $r;
            my $z = sin($theta) * $r;
            my ($cr, $cg, $cb) = hsv($hue + $s * 0.15, 0.6, 0.5 + $lift * 3);
            push @verts, $x, $y, $z, $cr, $cg, $cb, 0.75, 3.0 + $lift * 15;
        }
        push @draw_cmds, [$total, $samples + 1];
        $total += $samples + 1;
        $thread_id++;
    }

    # Longitude arcs
    for my $li (0 .. $lon_arcs - 1) {
        my $theta = $li / $lon_arcs * 2 * $PI;
        my $ev = $env_vals[$thread_id % @env_vals];
        my $hue = $thread_id / ($lat_rings + $lon_arcs + $diag_threads) + $t * 0.02 + 0.33;
        my $phase = $t * 0.4 + $thread_id * 0.5;

        for my $j (0 .. $samples) {
            my $s = $j / $samples;
            my $phi = $s * $PI;
            my $lift = $ev->[$j % $samples] * (1 + 0.3 * sin($phase + $s * 3));
            my $r = ($R + $lift) * sin($phi);
            my $y = ($R + $lift) * cos($phi);
            my $x = cos($theta) * $r;
            my $z = sin($theta) * $r;
            my ($cr, $cg, $cb) = hsv($hue + $s * 0.2, 0.65, 0.5 + $lift * 3);
            push @verts, $x, $y, $z, $cr, $cg, $cb, 0.7, 2.5 + $lift * 12;
        }
        push @draw_cmds, [$total, $samples + 1];
        $total += $samples + 1;
        $thread_id++;
    }

    # Diagonal great circles (tilted planes)
    for my $di (0 .. $diag_threads - 1) {
        my $tilt = ($di + 0.5) / $diag_threads * $PI;
        my $spin = $di * 2.399 + $t * 0.1;  # golden angle spread + rotation
        my $ev = $env_vals[$thread_id % @env_vals];
        my $hue = $thread_id / ($lat_rings + $lon_arcs + $diag_threads) + $t * 0.02 + 0.66;
        my $phase = $t * 0.6 + $di * 1.1;

        for my $j (0 .. $samples) {
            my $s = $j / $samples;
            my $a = $s * 2 * $PI;
            my $lift = $ev->[$j % $samples] * (1 + 0.4 * sin($phase + $s * 5));

            # Point on unit circle in XZ plane, then tilt and spin
            my $px = cos($a);
            my $py = 0;
            my $pz = sin($a);

            # Tilt around X axis
            my $ct = cos($tilt); my $st = sin($tilt);
            my $py2 = $py * $ct - $pz * $st;
            my $pz2 = $py * $st + $pz * $ct;

            # Spin around Y axis
            my $cs = cos($spin); my $ss = sin($spin);
            my $px2 = $px * $cs - $pz2 * $ss;
            my $pz3 = $px * $ss + $pz2 * $cs;

            my $x = $px2 * ($R + $lift);
            my $y = $py2 * ($R + $lift);
            my $z = $pz3 * ($R + $lift);

            my ($cr, $cg, $cb) = hsv($hue + $s * 0.25, 0.55, 0.55 + $lift * 3);
            push @verts, $x, $y, $z, $cr, $cg, $cb, 0.6, 2.0 + $lift * 10;
        }
        push @draw_cmds, [$total, $samples + 1];
        $total += $samples + 1;
        $thread_id++;
    }

    # Upload and draw
    my $stride = 8 * 4;
    my $oa = OpenGL::Array->new_list(GL_FLOAT, @verts);
    glBindVertexArray($vao);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo);
    glBufferData_c(GL_ARRAY_BUFFER, $oa->length, $oa->ptr, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, $stride, 0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer_c(1, 4, GL_FLOAT, GL_FALSE, $stride, 3*4);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer_c(2, 1, GL_FLOAT, GL_FALSE, $stride, 7*4);

    for my $cmd (@draw_cmds) {
        glDrawArrays(GL_LINE_STRIP, $cmd->[0], $cmd->[1]);
    }

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glDisableVertexAttribArray(2);
    glBindVertexArray(0);

    glutSwapBuffers();
}

sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_MULTISAMPLE);
glutInitContextVersion(3, 2);
glutInitContextProfile(0x0001);
glutInitWindowSize($W, $H);
glutCreateWindow('Envelope Thread Sphere');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Thread sphere: %d lat + %d lon + %d diag = %d threads — ESC to quit\n",
    $lat_rings, $lon_arcs, $diag_threads, $lat_rings + $lon_arcs + $diag_threads;
glutMainLoop();
