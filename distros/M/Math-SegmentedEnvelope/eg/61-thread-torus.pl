#!/usr/bin/env perl
# Thread torus: envelope-shaped threads woven around a torus surface
# Major rings (around the hole), minor rings (around the tube),
# and helical threads spiraling along the tube
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

my $major_r = 1.0;   # distance from center to tube center
my $minor_r = 0.4;   # tube radius
my $samples = 120;

# Thread displacement envelopes
my @thread_envs = (
    env([[0, 0.06, 0.12, 0.06, 0], [0.25, 0.25, 0.25, 0.25], [2, -2, 2, -2]],
        morpher_formula => 'smoothstep'),
    spline([0, 0.2, 0.5, 0.8, 1.0], [0, 0.10, 0.03, 0.08, 0]),
    adsr(0.1, 0.2, 0.02, 0.2, peak => 0.12, morpher_formula => 'sine'),
    perc(0.05, 0.95, peak => 0.08, morpher_formula => 'cubic_out'),
    env([[0, 0.04, 0.10, 0.04, 0], [0.25, 0.25, 0.25, 0.25], [3, -3, 3, -3]],
        morpher_formula => 'bounce_out'),
);

my @env_vals;
for my $i (0 .. $#thread_envs) {
    push @env_vals, [$thread_envs[$i]->table($samples)];
}

# Pulsing envelope
my $pulse = env([[1.0, 1.04, 1.0], [0.5, 0.5], [2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $pulse_s = $pulse->static;
my $pulse_d = $pulse->duration;

# Thread counts
my $major_rings = 24;    # rings going around the hole (toroidal direction)
my $minor_rings = 16;    # rings going around the tube (poloidal direction)
my $helix_threads = 12;  # helical threads spiraling along the tube
my $helix_wraps = 5;     # how many times each helix wraps around the tube

# Torus point: (u, v) in [0,1] -> (x, y, z)
# u = toroidal angle (around hole), v = poloidal angle (around tube)
sub torus_point {
    my ($u, $v, $R, $r) = @_;
    my $theta = $u * 2 * $PI;  # toroidal
    my $phi   = $v * 2 * $PI;  # poloidal
    my $x = ($R + $r * cos($phi)) * cos($theta);
    my $y = $r * sin($phi);
    my $z = ($R + $r * cos($phi)) * sin($theta);
    return ($x, $y, $z);
}

# Normal at torus surface (points outward from tube center)
sub torus_normal {
    my ($u, $v) = @_;
    my $theta = $u * 2 * $PI;
    my $phi   = $v * 2 * $PI;
    my $nx = cos($phi) * cos($theta);
    my $ny = sin($phi);
    my $nz = cos($phi) * sin($theta);
    return ($nx, $ny, $nz);
}

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
    my $p = $pulse_s->(fmod($t * 0.4, $pulse_d));
    my $R = $major_r * $p;
    my $r = $minor_r * $p;

    glClearColor(0.02, 0.02, 0.05, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    my $cam_a = $t * 0.18;
    my $cam_e = 0.8 + sin($t * 0.1) * 0.5;
    my @proj = mat4_perspective(50, $W/$H, 0.01, 20);
    my @view = mat4_lookat(
        cos($cam_a)*2.8, $cam_e, sin($cam_a)*2.8,
        0, 0, 0,  0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform2f($u_resolution, $W, $H);

    # per vertex: x,y,z, r,g,b,a, thick = 8 floats
    my @verts;
    my @draw_cmds;
    my $total = 0;
    my $tid = 0;

    # Major rings: circles around the hole (fixed poloidal angle v, sweep toroidal u)
    for my $mi (0 .. $major_rings - 1) {
        my $v = $mi / $major_rings;
        my $ev = $env_vals[$tid % @env_vals];
        my $hue = 0.0 + $tid / ($major_rings + $minor_rings + $helix_threads);
        my $phase = $t * 0.6 + $tid * 0.4;

        for my $j (0 .. $samples) {
            my $s = $j / $samples;
            my $u = $s;
            my $lift = $ev->[$j % $samples] * (1 + 0.3 * sin($phase + $s * 6));
            my ($nx, $ny, $nz) = torus_normal($u, $v);
            my ($px, $py, $pz) = torus_point($u, $v, $R, $r + $lift);
            my ($cr, $cg, $cb) = hsv($hue + $s * 0.1 + $t * 0.02, 0.6, 0.5 + $lift * 4);
            push @verts, $px, $py, $pz, $cr, $cg, $cb, 0.7, 2.5 + $lift * 15;
        }
        push @draw_cmds, [$total, $samples + 1];
        $total += $samples + 1;
        $tid++;
    }

    # Minor rings: circles around the tube (fixed toroidal u, sweep poloidal v)
    for my $mi (0 .. $minor_rings - 1) {
        my $u = $mi / $minor_rings + $t * 0.02;  # slowly rotate
        my $ev = $env_vals[$tid % @env_vals];
        my $hue = 0.33 + $tid / ($major_rings + $minor_rings + $helix_threads);
        my $phase = $t * 0.5 + $tid * 0.6;

        for my $j (0 .. $samples) {
            my $s = $j / $samples;
            my $v = $s;
            my $lift = $ev->[$j % $samples] * (1 + 0.4 * sin($phase + $s * 4));
            my ($px, $py, $pz) = torus_point($u, $v, $R, $r + $lift);
            my ($cr, $cg, $cb) = hsv($hue + $s * 0.15 + $t * 0.02, 0.65, 0.5 + $lift * 4);
            push @verts, $px, $py, $pz, $cr, $cg, $cb, 0.65, 2.0 + $lift * 12;
        }
        push @draw_cmds, [$total, $samples + 1];
        $total += $samples + 1;
        $tid++;
    }

    # Helical threads: spiral along tube surface
    for my $hi (0 .. $helix_threads - 1) {
        my $offset = $hi / $helix_threads;  # starting position around tube
        my $ev = $env_vals[$tid % @env_vals];
        my $hue = 0.66 + $tid / ($major_rings + $minor_rings + $helix_threads);
        my $phase = $t * 0.7 + $hi * 0.9;
        my $direction = ($hi % 2 == 0) ? 1 : -1;  # alternating helix direction

        for my $j (0 .. $samples) {
            my $s = $j / $samples;
            my $u = $s + $t * 0.03;  # toroidal: sweep around hole
            my $v = $offset + $s * $helix_wraps * $direction;  # poloidal: wrap around tube
            my $lift = $ev->[$j % $samples] * (1 + 0.3 * sin($phase + $s * 8));
            my ($px, $py, $pz) = torus_point($u, $v, $R, $r + $lift);
            my ($cr, $cg, $cb) = hsv($hue + $s * 0.3 + $t * 0.02, 0.55, 0.55 + $lift * 4);
            push @verts, $px, $py, $pz, $cr, $cg, $cb, 0.6, 1.8 + $lift * 10;
        }
        push @draw_cmds, [$total, $samples + 1];
        $total += $samples + 1;
        $tid++;
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
glutCreateWindow('Envelope Thread Torus');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Thread torus: %d major + %d minor + %d helix = %d threads — ESC to quit\n",
    $major_rings, $minor_rings, $helix_threads,
    $major_rings + $minor_rings + $helix_threads;
glutMainLoop();
