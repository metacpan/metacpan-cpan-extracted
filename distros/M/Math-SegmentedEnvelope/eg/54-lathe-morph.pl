#!/usr/bin/env perl
# Dynamic lathe morph: smoothly morph between envelope profiles while rotating
# The mesh re-generates every frame from a lerped envelope, creating fluid shape transitions
# Uses sine morpher for smooth loop (start == end level for seamless revolution)
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

use Math::SegmentedEnvelope qw(env);
use Time::HiRes qw(time);
use POSIX qw(floor tan);

my $W = 800;
my $H = 600;
my $PI = 3.14159265358979323846;
my $slices = 48;
my $stacks = 48;

# All profiles use matching segment counts for lerp compatibility.
# First and last levels are equal for seamless revolution (closed loop).
# Sine morpher ensures smooth curvature at the seam.
my $segs = 8;
my @profiles = (
    { name => 'Vase', color => [0.85, 0.55, 0.3],
      env => Math::SegmentedEnvelope->new(
        [[0.30, 0.35, 0.50, 0.20, 0.15, 0.40, 0.45, 0.42, 0.30],
         [0.12, 0.12, 0.13, 0.13, 0.12, 0.13, 0.12, 0.13],
         [2, 2, -3, -2, 3, 2, -2, -2]],
        morpher_formula => 'sine') },
    { name => 'Goblet', color => [0.7, 0.7, 0.85],
      env => Math::SegmentedEnvelope->new(
        [[0.30, 0.25, 0.03, 0.03, 0.05, 0.20, 0.35, 0.38, 0.30],
         [0.12, 0.12, 0.13, 0.13, 0.12, 0.13, 0.12, 0.13],
         [-2, -3, 1, 2, 3, 2, 1, -2]],
        morpher_formula => 'sine') },
    { name => 'Bell', color => [0.9, 0.75, 0.2],
      env => Math::SegmentedEnvelope->new(
        [[0.45, 0.50, 0.45, 0.30, 0.10, 0.05, 0.03, 0.02, 0.45],
         [0.12, 0.12, 0.13, 0.13, 0.12, 0.13, 0.12, 0.13],
         [2, -1, -2, -3, -2, -1, 1, 3]],
        morpher_formula => 'sine') },
    { name => 'Bulb', color => [0.4, 0.75, 0.5],
      env => Math::SegmentedEnvelope->new(
        [[0.10, 0.25, 0.40, 0.45, 0.40, 0.25, 0.10, 0.05, 0.10],
         [0.12, 0.12, 0.13, 0.13, 0.12, 0.13, 0.12, 0.13],
         [2, 2, 2, -2, -2, -2, -1, 2]],
        morpher_formula => 'sine') },
    { name => 'Hourglass', color => [0.5, 0.6, 0.9],
      env => Math::SegmentedEnvelope->new(
        [[0.35, 0.30, 0.10, 0.05, 0.10, 0.30, 0.35, 0.30, 0.35],
         [0.12, 0.12, 0.13, 0.13, 0.12, 0.13, 0.12, 0.13],
         [-2, -3, -2, 2, 3, 2, -1, -2]],
        morpher_formula => 'sine') },
);

# Morph timing
my $morph_time = 3.0;   # seconds per shape
my $trans_time = 1.5;    # transition duration

# Generate mesh vertices from an envelope
sub gen_mesh {
    my ($env_obj) = @_;
    my $s = $env_obj->static;
    my $dur = $env_obj->duration;
    my (@verts, @normals, @indices);

    for my $j (0 .. $stacks) {
        my $t = $j / $stacks;
        my $r = $s->($t * $dur);
        for my $i (0 .. $slices - 1) {
            my $th = $i / $slices * 2 * $PI;
            push @verts, cos($th) * $r, $t, sin($th) * $r;

            my $rp = $s->(($t > 0.01 ? $t - 0.01 : 0) * $dur);
            my $rn = $s->(($t < 0.99 ? $t + 0.01 : 1) * $dur);
            my $dr = ($rn - $rp) / 0.02;
            my ($nx, $nz, $ny) = (cos($th), sin($th), -$dr);
            my $nl = sqrt($nx*$nx + $ny*$ny + $nz*$nz) || 1;
            push @normals, $nx/$nl, $ny/$nl, $nz/$nl;
        }
    }

    for my $j (0 .. $stacks - 1) {
        for my $i (0 .. $slices - 1) {
            my $i2 = ($i + 1) % $slices;
            my ($a, $b, $c, $d) = (
                $j * $slices + $i,  $j * $slices + $i2,
                ($j+1) * $slices + $i, ($j+1) * $slices + $i2);
            push @indices, $a, $c, $b, $b, $c, $d;
        }
    }
    return (\@verts, \@normals, \@indices);
}

# Shaders (same as eg/53 but with dynamic re-upload)
my $vert_src = <<'GLSL';
#version 150
in vec3 aPos;
in vec3 aNormal;
out vec3 vNormal;
out vec3 vWorldPos;
uniform mat4 uMVP;
void main() {
    vNormal = aNormal;
    vWorldPos = aPos;
    gl_Position = uMVP * vec4(aPos, 1.0);
}
GLSL

my $geom_src = <<'GLSL';
#version 150
layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;
in vec3 vNormal[];
in vec3 vWorldPos[];
out vec4 frag_color;
uniform float uTime;
uniform vec3 uColor;

void main() {
    vec3 e1 = vWorldPos[1] - vWorldPos[0];
    vec3 e2 = vWorldPos[2] - vWorldPos[0];
    vec3 fn = normalize(cross(e1, e2));

    vec3 light = normalize(vec3(sin(uTime * 0.5), 0.8, cos(uTime * 0.5)));
    float diff = max(dot(fn, light), 0.0);
    float rim = 1.0 - max(dot(fn, normalize(vec3(0, 0, 1))), 0.0);

    for (int i = 0; i < 3; i++) {
        gl_Position = gl_in[i].gl_Position;
        vec3 col = uColor * (0.2 + diff * 0.8);
        col += vec3(0.2, 0.2, 0.3) * pow(rim, 3.0) * 0.6;
        // Height-based tint
        float h = vWorldPos[i].y;
        col = mix(col, col * 1.3, h);
        frag_color = vec4(col, 1.0);
        EmitVertex();
    }
    EndPrimitive();
}
GLSL

my $frag_src = <<'GLSL';
#version 150
in vec4 frag_color;
out vec4 outColor;
void main() { outColor = frag_color; }
GLSL

my ($prog, $u_mvp, $u_time, $u_color, $vao, $vbo_v, $vbo_n, $ibo);
my $num_idx;
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

sub upload_mesh {
    my ($v, $n, $ix) = @_;
    my $va = OpenGL::Array->new_list(GL_FLOAT, @$v);
    my $na = OpenGL::Array->new_list(GL_FLOAT, @$n);
    my $ia = OpenGL::Array->new_list(GL_UNSIGNED_INT, @$ix);

    glBindVertexArray($vao);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo_v);
    glBufferData_c(GL_ARRAY_BUFFER, $va->length, $va->ptr, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, 0, 0);

    glBindBuffer(GL_ARRAY_BUFFER, $vbo_n);
    glBufferData_c(GL_ARRAY_BUFFER, $na->length, $na->ptr, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer_c(1, 3, GL_FLOAT, GL_FALSE, 0, 0);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, $ibo);
    glBufferData_c(GL_ELEMENT_ARRAY_BUFFER, $ia->length, $ia->ptr, GL_DYNAMIC_DRAW);
    $num_idx = scalar @$ix;

    glBindVertexArray(0);
}

sub init_gl {
    my $vs = compile_shader(GL_VERTEX_SHADER, $vert_src);
    my $gs = compile_shader(GL_GEOMETRY_SHADER, $geom_src);
    my $fs = compile_shader(GL_FRAGMENT_SHADER, $frag_src);
    $prog = glCreateProgram();
    glAttachShader($prog, $_) for ($vs, $gs, $fs);
    glBindAttribLocation($prog, 0, 'aPos');
    glBindAttribLocation($prog, 1, 'aNormal');
    glLinkProgram($prog);
    my ($ok) = glGetProgramiv_p($prog, GL_LINK_STATUS);
    die "Link: ".glGetProgramInfoLog_p($prog) unless $ok;
    glDeleteShader($_) for ($vs, $gs, $fs);

    $u_mvp   = glGetUniformLocation($prog, 'uMVP');
    $u_time  = glGetUniformLocation($prog, 'uTime');
    $u_color = glGetUniformLocation($prog, 'uColor');

    ($vao) = glGenVertexArrays_p(1);
    ($vbo_v, $vbo_n, $ibo) = glGenBuffers_p(3);

    glEnable(GL_DEPTH_TEST);
    $start = time();
}

sub display {
    my $t = time() - $start;
    my $cycle = $morph_time + $trans_time;
    my $total_cycle = $cycle * scalar @profiles;
    my $phase = $t - floor($t / $total_cycle) * $total_cycle;

    my $shape_idx = int($phase / $cycle) % @profiles;
    my $in_shape = $phase - $shape_idx * $cycle;

    my ($env_current, $color);
    if ($in_shape < $morph_time) {
        # Holding current shape
        $env_current = $profiles[$shape_idx]{env};
        $color = $profiles[$shape_idx]{color};
    } else {
        # Morphing to next shape
        my $next_idx = ($shape_idx + 1) % @profiles;
        my $mix = ($in_shape - $morph_time) / $trans_time;
        # Smoothstep the mix
        $mix = $mix * $mix * (3 - 2 * $mix);

        $env_current = $profiles[$shape_idx]{env}->lerp(
            $profiles[$next_idx]{env}, $mix);
        # Blend colors
        my $ca = $profiles[$shape_idx]{color};
        my $cb = $profiles[$next_idx]{color};
        $color = [
            $ca->[0] * (1-$mix) + $cb->[0] * $mix,
            $ca->[1] * (1-$mix) + $cb->[1] * $mix,
            $ca->[2] * (1-$mix) + $cb->[2] * $mix,
        ];
    }

    # Re-generate and upload mesh
    my ($v, $n, $ix) = gen_mesh($env_current);
    upload_mesh($v, $n, $ix);

    glClearColor(0.06, 0.06, 0.1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    my $a = $t * 0.5;
    my @proj = mat4_perspective(40, $W/$H, 0.01, 10);
    my @view = mat4_lookat(cos($a)*1.3, 0.6, sin($a)*1.3, 0, 0.45, 0, 0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform1f($u_time, $t);
    glUniform3f($u_color, $color->[0], $color->[1], $color->[2]);

    glBindVertexArray($vao);
    glDrawElements_c(GL_TRIANGLES, $num_idx, GL_UNSIGNED_INT, 0);
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
glutCreateWindow('Envelope Lathe Morph');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Lathe morph: %d shapes, %d slices x %d stacks — ESC to quit\n",
    scalar @profiles, $slices, $stacks;
printf "Shapes: %s\n", join(', ', map { $_->{name} } @profiles);
glutMainLoop();
