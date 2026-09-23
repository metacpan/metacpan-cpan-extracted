#!/usr/bin/env perl
# Angular lathe morph: profile changes every 30 degrees around the axis
# Two orthogonal envelope profiles are multiplied at each angle to ensure
# smooth start-to-end transition (the product at 0° == product at 360°)
#
# Profile A controls the "base" radius, Profile B modulates it.
# At angle θ: radius(h) = profileA(h) * lerp(1.0, profileB(h), modulation(θ))
# where modulation(θ) is a smooth periodic function.
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
my $slices = 72;    # must be multiple of angular_steps for clean keyframes
my $stacks = 48;
my $angular_steps = 12;  # morph keyframe every 360/12 = 30 degrees

# Height profiles: N+1 = 9 levels each (8 segments) for lerp compatibility
my @height_profiles = (
    env([[0.30, 0.45, 0.50, 0.20, 0.15, 0.40, 0.45, 0.35, 0.30],
         [0.12, 0.12, 0.13, 0.13, 0.12, 0.13, 0.12, 0.13],
         [2, 2, -3, -2, 3, 2, -2, -2]],
        morpher_formula => 'sine'),  # Vase

    env([[0.35, 0.25, 0.08, 0.05, 0.08, 0.25, 0.38, 0.35, 0.35],
         [0.12, 0.12, 0.13, 0.13, 0.12, 0.13, 0.12, 0.13],
         [-2, -3, 1, 2, 3, 2, -1, -2]],
        morpher_formula => 'sine'),  # Goblet

    env([[0.40, 0.48, 0.42, 0.28, 0.12, 0.06, 0.04, 0.03, 0.40],
         [0.12, 0.12, 0.13, 0.13, 0.12, 0.13, 0.12, 0.13],
         [2, -1, -2, -3, -2, -1, 1, 3]],
        morpher_formula => 'sine'),  # Bell

    env([[0.12, 0.28, 0.42, 0.48, 0.42, 0.28, 0.12, 0.06, 0.12],
         [0.12, 0.12, 0.13, 0.13, 0.12, 0.13, 0.12, 0.13],
         [2, 2, 2, -2, -2, -2, -1, 2]],
        morpher_formula => 'sine'),  # Bulb
);

# Orthogonal modulation profiles (applied perpendicular to height)
# These create cross-section variation: lobes, flutes, star patterns
my @cross_profiles = (
    env([[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
         [0.12, 0.12, 0.13, 0.13, 0.12, 0.13, 0.12, 0.13],
         [1, 1, 1, 1, 1, 1, 1, 1]]),  # Circle (no modulation)

    env([[1.0, 0.85, 1.0, 0.85, 1.0, 0.85, 1.0, 0.85, 1.0],
         [0.12, 0.12, 0.13, 0.13, 0.12, 0.13, 0.12, 0.13],
         [2, -2, 2, -2, 2, -2, 2, -2]],
        morpher_formula => 'smoothstep'),  # 4-lobe

    env([[1.0, 0.7, 1.0, 0.7, 1.0, 0.7, 1.0, 0.7, 1.0],
         [0.12, 0.12, 0.13, 0.13, 0.12, 0.13, 0.12, 0.13],
         [3, -3, 3, -3, 3, -3, 3, -3]],
        morpher_formula => 'smoothstep'),  # Deep flutes
);

# Pre-sample all profiles
my @h_samples = map { [$_->table($stacks + 1)] } @height_profiles;
my @c_samples = map { [$_->table($stacks + 1)] } @cross_profiles;

# Animation state
my $morph_speed = 0.08;  # how fast height profiles cycle
my $cross_speed = 0.05;  # how fast cross-section evolves

sub gen_mesh {
    my ($t) = @_;
    my (@verts, @normals, @indices);

    for my $i (0 .. $slices - 1) {
        my $theta = $i / $slices * 2 * $PI;

        # Determine which two height profiles to lerp at this angle
        # Each angular_step (30°) is a keyframe, smoothly interpolated between
        my $angle_phase = $i / $slices + $t * $morph_speed;
        $angle_phase -= floor($angle_phase);
        my $key = $angle_phase * @height_profiles;
        my $key_idx = int($key) % @height_profiles;
        my $next_idx = ($key_idx + 1) % @height_profiles;
        my $key_frac = $key - floor($key);
        # Smoothstep the blend
        $key_frac = $key_frac * $key_frac * (3 - 2 * $key_frac);

        # Cross-section modulation: smooth periodic function
        my $cross_phase = $theta / (2 * $PI) * 4 + $t * $cross_speed;
        # Use sin² for smooth 0-1 modulation
        my $cross_mod = sin($cross_phase * $PI) ** 2;
        my $cross_idx = int($t * 0.3) % @cross_profiles;

        my @ha = @{$h_samples[$key_idx]};
        my @hb = @{$h_samples[$next_idx]};
        my @cx = @{$c_samples[$cross_idx]};

        for my $j (0 .. $stacks) {
            my $v = $j / $stacks;
            # Lerp height profiles
            my $r = $ha[$j] * (1 - $key_frac) + $hb[$j] * $key_frac;
            # Multiply by cross-section modulation
            my $cross_r = 1.0 * (1 - $cross_mod) + $cx[$j] * $cross_mod;
            $r *= $cross_r;

            my $x = cos($theta) * $r;
            my $z = sin($theta) * $r;
            my $y = $v;
            push @verts, $x, $y, $z;

            # Normal approximation
            my $r_prev = $j > 0
                ? ($ha[$j-1]*(1-$key_frac) + $hb[$j-1]*$key_frac) *
                  (1*(1-$cross_mod) + $cx[$j-1]*$cross_mod)
                : $r;
            my $r_next = $j < $stacks
                ? ($ha[$j+1]*(1-$key_frac) + $hb[$j+1]*$key_frac) *
                  (1*(1-$cross_mod) + $cx[$j+1]*$cross_mod)
                : $r;
            my $dr = ($r_next - $r_prev) * $stacks * 0.5;
            my ($nx, $nz, $ny) = (cos($theta), sin($theta), -$dr);
            my $nl = sqrt($nx*$nx + $ny*$ny + $nz*$nz) || 1;
            push @normals, $nx/$nl, $ny/$nl, $nz/$nl;
        }
    }

    # Indices: connect adjacent slices
    for my $i (0 .. $slices - 1) {
        my $i2 = ($i + 1) % $slices;
        for my $j (0 .. $stacks - 1) {
            my $a = $i * ($stacks + 1) + $j;
            my $b = $i2 * ($stacks + 1) + $j;
            my $c = $i * ($stacks + 1) + $j + 1;
            my $d = $i2 * ($stacks + 1) + $j + 1;
            push @indices, $a, $c, $b, $b, $c, $d;
        }
    }

    return (\@verts, \@normals, \@indices);
}

# Shaders
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

void main() {
    vec3 e1 = vWorldPos[1] - vWorldPos[0];
    vec3 e2 = vWorldPos[2] - vWorldPos[0];
    vec3 fn = normalize(cross(e1, e2));

    vec3 light1 = normalize(vec3(sin(uTime * 0.3), 0.8, cos(uTime * 0.3)));
    vec3 light2 = normalize(vec3(-0.5, 0.3, -0.7));
    float diff = max(dot(fn, light1), 0.0) * 0.7 + max(dot(fn, light2), 0.0) * 0.3;

    for (int i = 0; i < 3; i++) {
        gl_Position = gl_in[i].gl_Position;
        float h = vWorldPos[i].y;
        float angle = atan(vWorldPos[i].z, vWorldPos[i].x);

        // Color: height gradient + angle hue shift
        vec3 col;
        col.r = 0.5 + 0.3 * sin(angle * 2.0 + uTime * 0.5);
        col.g = 0.4 + 0.2 * h;
        col.b = 0.6 + 0.2 * cos(angle * 3.0 - uTime * 0.3);

        col *= 0.25 + diff * 0.75;

        float rim = 1.0 - max(dot(fn, normalize(vec3(0, 0.3, 1))), 0.0);
        col += vec3(0.15, 0.15, 0.25) * pow(rim, 3.0);

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

my ($prog, $u_mvp, $u_time, $vao, $vbo_v, $vbo_n, $ibo);
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
    $u_mvp  = glGetUniformLocation($prog, 'uMVP');
    $u_time = glGetUniformLocation($prog, 'uTime');
    ($vao) = glGenVertexArrays_p(1);
    ($vbo_v, $vbo_n, $ibo) = glGenBuffers_p(3);
    glEnable(GL_DEPTH_TEST);
    $start = time();
}

sub display {
    my $t = time() - $start;

    my ($v, $n, $ix) = gen_mesh($t);
    upload_mesh($v, $n, $ix);

    glClearColor(0.05, 0.05, 0.08, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    my $a = $t * 0.3;
    my @proj = mat4_perspective(40, $W/$H, 0.01, 10);
    my @view = mat4_lookat(cos($a)*1.4, 0.55+sin($t*0.2)*0.1, sin($a)*1.4,
                           0, 0.45, 0, 0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform1f($u_time, $t);

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
glutCreateWindow('Angular Profile Morph');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Angular morph: %d profiles x %d cross-sections, %d slices x %d stacks — ESC to quit\n",
    scalar @height_profiles, scalar @cross_profiles, $slices, $stacks;
glutMainLoop();
