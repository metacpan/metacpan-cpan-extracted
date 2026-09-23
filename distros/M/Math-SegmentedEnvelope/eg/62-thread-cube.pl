#!/usr/bin/env perl
# Thread cube: envelope-shaped threads woven along cube edges, faces, and diagonals
# Edge threads follow cube wireframe, face threads weave across each face,
# diagonal threads connect opposite corners through the interior
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
my $samples = 80;
my $half = 0.8;  # half-size of cube

# Thread displacement envelopes
my @thread_envs = (
    env([[0, 0.08, 0.15, 0.08, 0], [0.25, 0.25, 0.25, 0.25], [2, -2, 2, -2]],
        morpher_formula => 'smoothstep'),
    spline([0, 0.2, 0.5, 0.8, 1.0], [0, 0.12, 0.04, 0.10, 0]),
    adsr(0.1, 0.2, 0.03, 0.2, peak => 0.14, morpher_formula => 'sine'),
    perc(0.05, 0.95, peak => 0.10, morpher_formula => 'cubic_out'),
    env([[0, 0.05, 0.12, 0.05, 0], [0.25, 0.25, 0.25, 0.25], [3, -3, 3, -3]],
        morpher_formula => 'bounce_out'),
);

my @env_vals;
push @env_vals, [$_->table($samples)] for @thread_envs;

# Pulse
my $pulse = env([[1.0, 1.05, 1.0], [0.5, 0.5], [2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $pulse_s = $pulse->static;
my $pulse_d = $pulse->duration;

# Cube geometry
my @corners = (
    [-1,-1,-1], [ 1,-1,-1], [ 1, 1,-1], [-1, 1,-1],
    [-1,-1, 1], [ 1,-1, 1], [ 1, 1, 1], [-1, 1, 1],
);

my @edges = (
    [0,1],[1,2],[2,3],[3,0],  # back face
    [4,5],[5,6],[6,7],[7,4],  # front face
    [0,4],[1,5],[2,6],[3,7],  # connecting
);

# Face definitions: [corner indices, normal axis, normal sign]
my @faces = (
    { corners => [0,1,2,3], axis => 2, sign => -1 },  # back  (Z-)
    { corners => [4,5,6,7], axis => 2, sign =>  1 },  # front (Z+)
    { corners => [0,1,5,4], axis => 1, sign => -1 },  # bottom (Y-)
    { corners => [3,2,6,7], axis => 1, sign =>  1 },  # top (Y+)
    { corners => [0,3,7,4], axis => 0, sign => -1 },  # left (X-)
    { corners => [1,2,6,5], axis => 0, sign =>  1 },  # right (X+)
);

# Space diagonals
my @diagonals = ([0,6], [1,7], [2,4], [3,5]);

# Face thread count per face
my $face_threads = 5;

# Shaders (same ribbon pipeline)
my $vert_src = <<'GLSL';
#version 150
in vec3 aPos; in vec4 aColor; in float aThick;
out VS_OUT { vec4 color; float thick; } vs_out;
uniform mat4 uMVP;
void main() {
    gl_Position = uMVP * vec4(aPos, 1.0);
    vs_out.color = aColor; vs_out.thick = aThick;
}
GLSL

my $geom_src = <<'GLSL';
#version 150
layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;
in VS_OUT { vec4 color; float thick; } gs_in[];
out vec4 gColor; out float gEdge;
uniform vec2 uResolution;
void main() {
    vec4 p0 = gl_in[0].gl_Position, p1 = gl_in[1].gl_Position;
    vec2 d = normalize(p1.xy/p1.w - p0.xy/p0.w);
    vec2 n = vec2(-d.y, d.x);
    float t0 = gs_in[0].thick/uResolution.y, t1 = gs_in[1].thick/uResolution.y;
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
in vec4 gColor; in float gEdge;
out vec4 outColor;
void main() {
    float d = abs(gEdge);
    float alpha = 1.0 - smoothstep(0.3, 1.0, d);
    float sheen = exp(-d*d*5.0) * 0.2;
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
    $m[10]=($f+$n)/($n-$f); $m[11]=-1; $m[14]=2*$f*$n/($n-$f); @m;
}
sub mat4_lookat {
    my($ex,$ey,$ez,$cx,$cy,$cz,$ux,$uy,$uz)=@_;
    my @f=($cx-$ex,$cy-$ey,$cz-$ez);
    my $l=sqrt($f[0]**2+$f[1]**2+$f[2]**2); @f=map{$_/$l}@f;
    my @s=($f[1]*$uz-$f[2]*$uy,$f[2]*$ux-$f[0]*$uz,$f[0]*$uy-$f[1]*$ux);
    $l=sqrt($s[0]**2+$s[1]**2+$s[2]**2); @s=map{$_/$l}@s;
    my @u=($s[1]*$f[2]-$s[2]*$f[1],$s[2]*$f[0]-$s[0]*$f[2],$s[0]*$f[1]-$s[1]*$f[0]);
    ($s[0],$u[0],-$f[0],0,$s[1],$u[1],-$f[1],0,$s[2],$u[2],-$f[2],0,
     -($s[0]*$ex+$s[1]*$ey+$s[2]*$ez),-($u[0]*$ex+$u[1]*$ey+$u[2]*$ez),
     $f[0]*$ex+$f[1]*$ey+$f[2]*$ez,1);
}
sub mat4_mult {
    my($a,$b)=@_;my @r=(0)x16;
    for my $i(0..3){for my $j(0..3){for my $k(0..3){$r[$j*4+$i]+=$a->[$k*4+$i]*$b->[$j*4+$k]}}}@r;
}
sub hsv {
    my($h,$s,$v)=@_;$h=($h-floor($h))*6;my $f=$h-floor($h);
    my $p=$v*(1-$s);my $q=$v*(1-$s*$f);my $t=$v*(1-$s*(1-$f));
    my @c=([$v,$t,$p],[$q,$v,$p],[$p,$v,$t],[$p,$q,$v],[$t,$p,$v],[$v,$p,$q]);
    @{$c[int($h)%6]};
}
sub fmod { $_[0] - floor($_[0]/$_[1])*$_[1] }

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

# Generate a thread between two 3D points with envelope displacement along a given perpendicular
sub thread_between {
    my ($from, $to, $perp, $ev, $tid, $t, $hue_base) = @_;
    my @verts;
    my $phase = $t * 0.5 + $tid * 0.7;

    for my $j (0 .. $samples) {
        my $s = $j / $samples;
        my $lift = $ev->[$j % $samples] * (1 + 0.3 * sin($phase + $s * 5));

        my $x = $from->[0] + ($to->[0] - $from->[0]) * $s + $perp->[0] * $lift;
        my $y = $from->[1] + ($to->[1] - $from->[1]) * $s + $perp->[1] * $lift;
        my $z = $from->[2] + ($to->[2] - $from->[2]) * $s + $perp->[2] * $lift;

        my ($cr, $cg, $cb) = hsv($hue_base + $s * 0.15 + $t * 0.02, 0.6, 0.5 + $lift * 3);
        push @verts, $x, $y, $z, $cr, $cg, $cb, 0.7, 2.5 + $lift * 14;
    }
    return @verts;
}

sub display {
    my $t = time() - $start;
    my $p = $pulse_s->(fmod($t * 0.4, $pulse_d));
    my $sz = $half * $p;

    glClearColor(0.02, 0.02, 0.05, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    my $cam_a = $t * 0.2;
    my $cam_e = sin($t * 0.13) * 0.6;
    my @proj = mat4_perspective(50, $W/$H, 0.01, 20);
    my @view = mat4_lookat(
        cos($cam_a)*3, 1.2+$cam_e, sin($cam_a)*3,
        0, 0, 0,  0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform2f($u_resolution, $W, $H);

    my @all_verts;
    my @draw_cmds;
    my $total = 0;
    my $tid = 0;

    # Scale corners
    my @sc = map { [$_->[0]*$sz, $_->[1]*$sz, $_->[2]*$sz] } @corners;

    # Edge threads
    for my $edge (@edges) {
        my ($a, $b) = @$edge;
        my $ev = $env_vals[$tid % @env_vals];
        # Perpendicular: cross product of edge direction with a reference
        my @dir = ($sc[$b][0]-$sc[$a][0], $sc[$b][1]-$sc[$a][1], $sc[$b][2]-$sc[$a][2]);
        my $dl = sqrt($dir[0]**2 + $dir[1]**2 + $dir[2]**2) || 1;
        @dir = map { $_/$dl } @dir;
        my @ref = (abs($dir[1]) < 0.9) ? (0,1,0) : (1,0,0);
        my @perp = ($dir[1]*$ref[2]-$dir[2]*$ref[1],
                    $dir[2]*$ref[0]-$dir[0]*$ref[2],
                    $dir[0]*$ref[1]-$dir[1]*$ref[0]);

        push @all_verts, thread_between($sc[$a], $sc[$b], \@perp, $ev, $tid, $t, 0.0 + $tid*0.03);
        push @draw_cmds, [$total, $samples + 1];
        $total += $samples + 1;
        $tid++;
    }

    # Face threads: parallel lines across each face
    for my $face (@faces) {
        my @ci = @{$face->{corners}};
        my $ax = $face->{axis};
        my $sgn = $face->{sign};
        # Normal direction for displacement
        my @norm = (0, 0, 0);
        $norm[$ax] = $sgn;

        for my $fi (0 .. $face_threads - 1) {
            my $frac = ($fi + 1) / ($face_threads + 1);
            # Interpolate start/end points along two edges of the face
            my @from = map { $sc[$ci[0]][$_] * (1-$frac) + $sc[$ci[3]][$_] * $frac } 0..2;
            my @to   = map { $sc[$ci[1]][$_] * (1-$frac) + $sc[$ci[2]][$_] * $frac } 0..2;

            my $ev = $env_vals[$tid % @env_vals];
            push @all_verts, thread_between(\@from, \@to, \@norm, $ev, $tid, $t, 0.33 + $tid*0.02);
            push @draw_cmds, [$total, $samples + 1];
            $total += $samples + 1;
            $tid++;
        }
    }

    # Space diagonal threads
    for my $diag (@diagonals) {
        my ($a, $b) = @$diag;
        my $ev = $env_vals[$tid % @env_vals];
        my @dir = ($sc[$b][0]-$sc[$a][0], $sc[$b][1]-$sc[$a][1], $sc[$b][2]-$sc[$a][2]);
        my $dl = sqrt($dir[0]**2 + $dir[1]**2 + $dir[2]**2) || 1;
        @dir = map { $_/$dl } @dir;
        # Perpendicular in a rotating direction
        my $rot = $t * 0.3 + $tid;
        my @perp = (-$dir[1]*cos($rot) + $dir[2]*sin($rot),
                     $dir[0]*cos($rot),
                    -$dir[0]*sin($rot));

        push @all_verts, thread_between($sc[$a], $sc[$b], \@perp, $ev, $tid, $t, 0.66 + $tid*0.04);
        push @draw_cmds, [$total, $samples + 1];
        $total += $samples + 1;
        $tid++;
    }

    # Upload and draw
    my $stride = 8 * 4;
    my $oa = OpenGL::Array->new_list(GL_FLOAT, @all_verts);
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
glutCreateWindow('Envelope Thread Cube');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

my $total_threads = scalar(@edges) + scalar(@faces) * $face_threads + scalar(@diagonals);
printf "Thread cube: %d edge + %d face + %d diagonal = %d threads — ESC to quit\n",
    scalar(@edges), scalar(@faces) * $face_threads, scalar(@diagonals), $total_threads;
glutMainLoop();
