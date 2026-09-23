#!/usr/bin/env perl
# Dynamic waves via geometry shader: envelope controls wave parameters
# Points are expanded into thick anti-aliased line segments by the geometry shader
# Multiple wave layers with different envelope-driven amplitudes and phases
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

use Math::SegmentedEnvelope qw(adsr perc env spline);
use Time::HiRes qw(time);

my $W = 900;
my $H = 500;

# Wave envelopes: control amplitude, frequency, phase speed, thickness
my $amp_env = adsr(0.2, 0.3, 0.6, 0.5,
    morpher_formula => 'smoothstep');
my $freq_env = spline([0, 0.3, 0.7, 1.0], [2, 8, 3, 6],
    is_fold_over => 1);
my $speed_env = env([[1, 3, 1], [0.5, 0.5], [2, -2]],
    morpher_formula => 'cubic_inout',
    is_fold_over => 1);
my $thick_env = spline([0, 0.5, 1.0], [2, 6, 2],
    is_fold_over => 1);

my $amp_s   = $amp_env->static;
my $freq_s  = $freq_env->static;
my $speed_s = $speed_env->static;
my $thick_s = $thick_env->static;

my $amp_d   = $amp_env->duration;
my $freq_d  = $freq_env->duration;
my $speed_d = $speed_env->duration;
my $thick_d = $thick_env->duration;

# Shader sources
my $vert_src = <<'GLSL';
#version 150
in vec2 aPos;
out float vPhase;
void main() {
    gl_Position = vec4(aPos, 0.0, 1.0);
    vPhase = (aPos.x + 1.0) * 0.5;  // 0..1 across screen
}
GLSL

my $geom_src = <<'GLSL';
#version 150
layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;

in float vPhase[];
out float gEdge;  // -1..1 distance from center for anti-aliasing

uniform float uThickness;
uniform vec2 uResolution;

void main() {
    vec2 p0 = gl_in[0].gl_Position.xy;
    vec2 p1 = gl_in[1].gl_Position.xy;

    // Direction and normal in screen space
    vec2 dir = normalize(p1 - p0);
    vec2 norm = vec2(-dir.y, dir.x);

    // Thickness in NDC
    float t = uThickness / uResolution.y;

    gEdge = -1.0;
    gl_Position = vec4(p0 - norm * t, 0.0, 1.0); EmitVertex();
    gEdge = 1.0;
    gl_Position = vec4(p0 + norm * t, 0.0, 1.0); EmitVertex();
    gEdge = -1.0;
    gl_Position = vec4(p1 - norm * t, 0.0, 1.0); EmitVertex();
    gEdge = 1.0;
    gl_Position = vec4(p1 + norm * t, 0.0, 1.0); EmitVertex();
    EndPrimitive();
}
GLSL

my $frag_src = <<'GLSL';
#version 150
in float gEdge;
out vec4 fragColor;

uniform vec4 uColor;

void main() {
    // Anti-aliased edge
    float d = abs(gEdge);
    float alpha = 1.0 - smoothstep(0.6, 1.0, d);
    fragColor = vec4(uColor.rgb, uColor.a * alpha);
}
GLSL

my ($prog, $u_color, $u_thickness, $u_resolution, $vbo, $vao);
my $start = time();
sub fmod { $_[0] - int($_[0] / $_[1]) * $_[1] }

sub compile_shader {
    my ($type, $src) = @_;
    my $shader = glCreateShader($type);
    glShaderSource_p($shader, $src);
    glCompileShader($shader);
    my ($ok) = glGetShaderiv_p($shader, GL_COMPILE_STATUS);
    unless ($ok) {
        my $log = glGetShaderInfoLog_p($shader);
        die "Shader error: $log\n";
    }
    return $shader;
}

sub init_gl {
    my $vs = compile_shader(GL_VERTEX_SHADER, $vert_src);
    my $gs = compile_shader(GL_GEOMETRY_SHADER, $geom_src);
    my $fs = compile_shader(GL_FRAGMENT_SHADER, $frag_src);

    $prog = glCreateProgram();
    glAttachShader($prog, $vs);
    glAttachShader($prog, $gs);
    glAttachShader($prog, $fs);
    glBindAttribLocation($prog, 0, 'aPos');
    glLinkProgram($prog);

    my ($link_ok) = glGetProgramiv_p($prog, GL_LINK_STATUS);
    unless ($link_ok) {
        my $log = glGetProgramInfoLog_p($prog);
        die "Link error: $log\n";
    }

    glDeleteShader($vs);
    glDeleteShader($gs);
    glDeleteShader($fs);

    $u_color      = glGetUniformLocation($prog, 'uColor');
    $u_thickness  = glGetUniformLocation($prog, 'uThickness');
    $u_resolution = glGetUniformLocation($prog, 'uResolution');

    ($vbo) = glGenBuffers_p(1);
    ($vao) = glGenVertexArrays_p(1);

    glBindVertexArray($vao);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
    glBindVertexArray(0);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

sub draw_wave {
    my ($verts, $r, $g, $b, $a, $thickness) = @_;
    my $n = scalar(@$verts) / 2;
    return if $n < 2;

    my $oa = OpenGL::Array->new_list(GL_FLOAT, @$verts);
    glBindVertexArray($vao);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo);
    glBufferData_c(GL_ARRAY_BUFFER, $oa->length, $oa->ptr, GL_DYNAMIC_DRAW);

    glUniform4f($u_color, $r, $g, $b, $a);
    glUniform1f($u_thickness, $thickness);
    glDrawArrays(GL_LINE_STRIP, 0, $n);
    glBindVertexArray(0);
}

sub display {
    my $t = time() - $start;

    # Sample envelopes
    my $amp   = $amp_s->(fmod($t, $amp_d));
    my $freq  = $freq_s->(fmod($t, $freq_d));
    my $speed = $speed_s->(fmod($t, $speed_d));
    my $thick = $thick_s->(fmod($t, $thick_d));

    glClearColor(0.04, 0.04, 0.07, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    glUseProgram($prog);
    glUniform2f($u_resolution, $W, $H);

    my $points = 200;
    my $pi2 = 6.28318530718;

    # Layer 1: main wave
    my @wave1;
    for my $i (0 .. $points) {
        my $x = -1 + 2 * $i / $points;
        my $phase = $i / $points * $pi2 * $freq + $t * $speed * 2;
        my $y = sin($phase) * $amp * 0.4;
        push @wave1, $x, $y;
    }
    draw_wave(\@wave1, 0.3, 0.6, 1.0, 0.9, $thick);

    # Layer 2: harmonic (2x freq, half amp, phase offset)
    my @wave2;
    for my $i (0 .. $points) {
        my $x = -1 + 2 * $i / $points;
        my $phase = $i / $points * $pi2 * $freq * 2 + $t * $speed * 3 + 1.5;
        my $y = sin($phase) * $amp * 0.2;
        push @wave2, $x, $y;
    }
    draw_wave(\@wave2, 1.0, 0.4, 0.3, 0.6, $thick * 0.6);

    # Layer 3: sub-harmonic (0.5x freq, offset)
    my @wave3;
    for my $i (0 .. $points) {
        my $x = -1 + 2 * $i / $points;
        my $phase = $i / $points * $pi2 * $freq * 0.5 + $t * $speed + 3;
        my $y = sin($phase) * $amp * 0.3 - 0.15;
        push @wave3, $x, $y;
    }
    draw_wave(\@wave3, 0.3, 0.9, 0.4, 0.5, $thick * 0.8);

    # Layer 4: noise-modulated (envelope * noise)
    my @wave4;
    for my $i (0 .. $points) {
        my $x = -1 + 2 * $i / $points;
        my $phase = $i / $points * $pi2 * $freq * 3 + $t * $speed * 5;
        my $noise = sin($phase) * sin($phase * 1.7 + $t) * sin($phase * 0.3 - $t * 2);
        my $y = $noise * $amp * 0.15 + 0.3;
        push @wave4, $x, $y;
    }
    draw_wave(\@wave4, 0.8, 0.3, 0.9, 0.4, $thick * 0.5);

    # Center line
    draw_wave([-1, 0, 1, 0], 1, 1, 1, 0.08, 1);

    glutSwapBuffers();
}

sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

# Main
glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_MULTISAMPLE);
glutInitContextVersion(3, 2);
glutInitContextProfile(0x0001);  # GLUT_CORE_PROFILE
glutInitWindowSize($W, $H);
glutCreateWindow('Envelope Geometry Waves');

init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

print "Geometry shader waves — ESC to quit\n";
glutMainLoop();
