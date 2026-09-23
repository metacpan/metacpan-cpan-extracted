#!/usr/bin/env perl
# Rainbow lattice: envelope-shaped ribbons radiating from center in 3D
# Each arm is a different envelope profile extruded along a direction,
# with geometry shader expanding points into thick ribbons.
# Arms spread outward with rainbow hue cycling and pulsing amplitude.
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

use Math::SegmentedEnvelope qw(adsr perc asr spline env);
use Time::HiRes qw(time);
use POSIX qw(tan floor);

my $W = 900;
my $H = 700;
my $PI = 3.14159265358979323846;

# Number of radiating arms
my $num_arms = 108;
my $samples = 80;

# Each arm gets a different envelope profile
my @arm_envs = (
    adsr(0.05, 0.15, 0.5, 0.3, morpher_formula => 'smoothstep'),
    perc(0.02, 0.8, morpher_formula => 'cubic_out'),
    spline([0, 0.2, 0.5, 0.8, 1.0], [0, 0.8, 0.3, 0.9, 0]),
    asr(0.1, 0.5, 0.4, morpher_formula => 'smoothstep'),
    env([[0, 1, 0.2, 0.8, 0], [0.2, 0.2, 0.3, 0.3], [3, -2, 2, -3]],
        morpher_formula => 'bounce_out'),
    env([[0, 0.5, 1, 0.5, 0], [0.25, 0.25, 0.25, 0.25], [2, -2, 2, -2]],
        morpher_formula => 'elastic_out'),
);

# Pre-sample all envelope profiles
my @arm_vals;
for my $i (0 .. $num_arms - 1) {
    my $e = $arm_envs[$i % @arm_envs];
    push @arm_vals, [$e->table($samples)];
}

# Pulse envelope: modulates all arm amplitudes
my $pulse = env([[0.5, 1.0, 0.5], [0.5, 0.5], [2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $pulse_s = $pulse->static;
my $pulse_d = $pulse->duration;

# Spread envelope: controls how far arms extend over time
my $spread = env([[0, 1], [2], [2]],
    morpher_formula => 'cubic_out', is_hold => 1);
my $spread_s = $spread->static;
my $spread_d = $spread->duration;

my $vert_src = <<'GLSL';
#version 150
in vec3 aPos;
in vec3 aColor;
in float aThick;
out VS_OUT {
    vec3 color;
    float thick;
} vs_out;
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

in VS_OUT {
    vec3 color;
    float thick;
} gs_in[];

out vec3 gColor;
out float gEdge;

uniform vec2 uResolution;

void main() {
    vec4 p0 = gl_in[0].gl_Position;
    vec4 p1 = gl_in[1].gl_Position;

    // Screen-space direction
    vec2 d = normalize(p1.xy/p1.w - p0.xy/p0.w);
    vec2 n = vec2(-d.y, d.x);

    // Thickness varies per vertex
    float t0 = gs_in[0].thick / uResolution.y;
    float t1 = gs_in[1].thick / uResolution.y;

    gColor = gs_in[0].color; gEdge = -1.0;
    gl_Position = vec4(p0.xy/p0.w - n * t0, p0.z/p0.w, 1.0) * vec4(p0.w, p0.w, p0.w, 1.0);
    gl_Position = vec4(p0.xy - n * t0 * p0.w, p0.zw);
    EmitVertex();

    gColor = gs_in[0].color; gEdge = 1.0;
    gl_Position = vec4(p0.xy + n * t0 * p0.w, p0.zw);
    EmitVertex();

    gColor = gs_in[1].color; gEdge = -1.0;
    gl_Position = vec4(p1.xy - n * t1 * p1.w, p1.zw);
    EmitVertex();

    gColor = gs_in[1].color; gEdge = 1.0;
    gl_Position = vec4(p1.xy + n * t1 * p1.w, p1.zw);
    EmitVertex();

    EndPrimitive();
}
GLSL

my $frag_src = <<'GLSL';
#version 150
in vec3 gColor;
in float gEdge;
out vec4 outColor;

void main() {
    float d = abs(gEdge);
    float alpha = 1.0 - smoothstep(0.5, 1.0, d);
    // Glow effect: add brightness at center
    float glow = exp(-d * d * 4.0) * 0.3;
    outColor = vec4(gColor + glow, alpha * 0.85);
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
    my ($h,$s,$v) = @_;
    $h = ($h - floor($h)) * 6;
    my $f = $h - floor($h);
    my $p = $v*(1-$s); my $q = $v*(1-$s*$f); my $t = $v*(1-$s*(1-$f));
    my @c = ([$v,$t,$p],[$q,$v,$p],[$p,$v,$t],[$p,$q,$v],[$t,$p,$v],[$v,$p,$q]);
    return @{$c[int($h)%6]};
}

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
    glDepthFunc(GL_LEQUAL);

    $start = time();
}

sub display {
    my $t = time() - $start;
    my $pulse_val = $pulse_s->($t - floor($t / $pulse_d) * $pulse_d);
    my $spread_val = $spread_s->($t < $spread_d ? $t : $spread_d);

    glClearColor(0.02, 0.02, 0.04, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    # Orbiting camera
    my $cam_a = $t * 0.2;
    my $cam_h = 1.5 + sin($t * 0.15) * 0.5;
    my @proj = mat4_perspective(50, $W/$H, 0.01, 20);
    my @view = mat4_lookat(
        cos($cam_a) * 3, $cam_h, sin($cam_a) * 3,
        0, 0, 0,
        0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform2f($u_resolution, $W, $H);

    # Build all arms into one vertex buffer
    # Per vertex: x,y,z, r,g,b, thickness (7 floats)
    my @all_verts;

    for my $arm (0 .. $num_arms - 1) {
        my @vals = @{$arm_vals[$arm]};

        # Direction: spread in 3D using golden angle for even distribution
        my $golden = $PI * (3 - sqrt(5));  # golden angle
        my $theta = $arm * $golden;
        my $phi = acos(1 - 2 * ($arm + 0.5) / $num_arms);

        my $dx = sin($phi) * cos($theta);
        my $dy = cos($phi);
        my $dz = sin($phi) * sin($theta);

        # Per-arm direction modulation: each arm sways independently
        my $sway_freq = 0.4 + $arm * 0.037;  # slightly different freq per arm
        my $sway_amp = 0.15 + 0.05 * sin($arm * 1.7);
        my $sway_theta = sin($t * $sway_freq) * $sway_amp;
        my $sway_phi = cos($t * $sway_freq * 0.7 + $arm) * $sway_amp * 0.6;

        # Apply sway as small rotation around perpendicular axes
        my $ct = cos($sway_theta);
        my $st = sin($sway_theta);
        my $cp = cos($sway_phi);
        my $sp = sin($sway_phi);

        # Rotate around Y then X
        my $dx2 = $dx * $ct - $dz * $st;
        my $dz2 = $dx * $st + $dz * $ct;
        my $dy2 = $dy * $cp - $dz2 * $sp;
        $dz2    = $dy * $sp + $dz2 * $cp;

        # Hue: rainbow spread + slow rotation
        my $base_hue = $arm / $num_arms + $t * 0.05;

        for my $i (0 .. $samples - 1) {
            my $s = $i / ($samples - 1);
            my $amp = $vals[$i] * $pulse_val;
            my $reach = $s * $spread_val * 2.0;

            # Position along arm direction
            my $x = $dx2 * $reach;
            my $y = $dy2 * $reach + $amp * 0.3 * sin($s * $PI * 2 + $t * 2);
            my $z = $dz2 * $reach;

            # Wobble perpendicular to direction
            my $wobble = $amp * 0.15 * sin($s * $PI * 4 + $t * 3 + $arm);
            $x += $wobble * (-$dz2);
            $z += $wobble * $dx2;

            # Color: rainbow hue + brightness from envelope amplitude
            my ($r, $g, $b) = hsv($base_hue + $s * 0.3, 0.8, 0.5 + $amp * 0.5);

            # Thickness: modulated by envelope value
            my $thick = 2 + $amp * 8;

            push @all_verts, $x, $y, $z, $r, $g, $b, $thick;
        }
    }

    # Upload and draw
    my $stride = 7 * 4;  # 7 floats * 4 bytes
    my $oa = OpenGL::Array->new_list(GL_FLOAT, @all_verts);

    glBindVertexArray($vao);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo);
    glBufferData_c(GL_ARRAY_BUFFER, $oa->length, $oa->ptr, GL_DYNAMIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, $stride, 0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer_c(1, 3, GL_FLOAT, GL_FALSE, $stride, 3 * 4);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer_c(2, 1, GL_FLOAT, GL_FALSE, $stride, 6 * 4);

    # Draw each arm as a separate line strip
    for my $arm (0 .. $num_arms - 1) {
        glDrawArrays(GL_LINE_STRIP, $arm * $samples, $samples);
    }

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glDisableVertexAttribArray(2);
    glBindVertexArray(0);

    glutSwapBuffers();
}

sub acos { atan2(sqrt(1 - $_[0]*$_[0]), $_[0]) }
sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_MULTISAMPLE);
glutInitContextVersion(3, 2);
glutInitContextProfile(0x0001);
glutInitWindowSize($W, $H);
glutCreateWindow('Rainbow Envelope Lattice');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Rainbow lattice: %d arms x %d samples, %d envelope profiles — ESC to quit\n",
    $num_arms, $samples, scalar @arm_envs;
glutMainLoop();
