#!/usr/bin/env perl
# Pure OpenGL::Modern envelope scope: GL buffers, shaders, 60fps
# No C helpers -- everything via Perl OpenGL::Modern + GLUT
#
# Requires: OpenGL::Modern, OpenGL::GLUT
use strict;
use warnings;

BEGIN {
    eval { require OpenGL::Modern; OpenGL::Modern->import(':all'); 1 }
        or die "This example requires OpenGL::Modern\n";
    eval { require OpenGL::GLUT; OpenGL::GLUT->import(':all'); 1 }
        or die "This example requires OpenGL::GLUT\n";
}

use Math::SegmentedEnvelope qw(adsr perc spline env);
use Time::HiRes qw(time);

my $W = 800;
my $H = 450;
my $PAD = 0.1;  # normalized padding

# Envelopes
my @curves = (
    { env => adsr(0.1, 0.15, 0.7, 0.3, morpher_formula => 'smoothstep'),
      r => 0.24, g => 0.55, b => 1.0, label => 'ADSR' },
    { env => perc(0.01, 0.5, morpher_formula => 'cubic_out'),
      r => 1.0, g => 0.35, b => 0.24, label => 'Perc' },
    { env => spline([0, 0.2, 0.5, 0.8, 1.0], [0, 0.9, 0.2, 0.8, 0]),
      r => 0.24, g => 0.82, b => 0.35, label => 'Spline' },
    { env => env([[0, 1], [1], [1]], morpher_formula => 'bounce_out'),
      r => 0.82, g => 0.35, b => 0.94, label => 'Bounce' },
);

my $samples = 512;
for my $c (@curves) {
    $c->{vals} = [$c->{env}->table($samples)];
    $c->{static} = $c->{env}->static;
}

my $active_idx = 0;
my $next_idx = 1;
my $last_switch = time();
my $morph_duration = 2.0;
my $hold_duration = 2.0;
my $morphing = 0;
my $morph_start = 0;
my @morph_vals;
my $phase_accum = 0;       # continuous phase [0,1), never resets
my $last_t = time();

# Shader sources
my $vert_src = <<'GLSL';
#version 120
attribute vec2 aPos;
void main() {
    gl_Position = vec4(aPos, 0.0, 1.0);
}
GLSL

my $frag_src = <<'GLSL';
#version 120
uniform vec4 uColor;
void main() {
    gl_FragColor = uColor;
}
GLSL

my ($prog, $u_color, $vbo);

sub compile_shader {
    my ($type, $src) = @_;
    my $shader = glCreateShader($type);
    glShaderSource_p($shader, $src);
    glCompileShader($shader);
    my ($ok) = glGetShaderiv_p($shader, GL_COMPILE_STATUS);
    unless ($ok) {
        my $log = glGetShaderInfoLog_p($shader);
        die "Shader compile: $log\n";
    }
    return $shader;
}

sub init_gl {
    my $vs = compile_shader(GL_VERTEX_SHADER, $vert_src);
    my $fs = compile_shader(GL_FRAGMENT_SHADER, $frag_src);

    $prog = glCreateProgram();
    glAttachShader($prog, $vs);
    glAttachShader($prog, $fs);
    glBindAttribLocation($prog, 0, 'aPos');
    glLinkProgram($prog);
    glDeleteShader($vs);
    glDeleteShader($fs);

    $u_color = glGetUniformLocation($prog, 'uColor');

    ($vbo) = glGenBuffers_p(1);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_LINE_SMOOTH);
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
}

my $oa;
BEGIN { eval { require OpenGL::Array } }

sub upload_line {
    my ($verts_ref) = @_;
    $oa = OpenGL::Array->new_list(GL_FLOAT, @$verts_ref);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo);
    glBufferData_c(GL_ARRAY_BUFFER, $oa->length, $oa->ptr, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
}

sub draw_line_strip {
    my ($verts_ref, $r, $g, $b, $a, $width) = @_;
    $width //= 2.0;
    my $n = scalar(@$verts_ref) / 2;
    upload_line($verts_ref);
    glUniform4f($u_color, $r, $g, $b, $a);
    glLineWidth($width);
    glDrawArrays(GL_LINE_STRIP, 0, $n);
}

sub draw_triangle_strip {
    my ($verts_ref, $r, $g, $b, $a) = @_;
    my $n = scalar(@$verts_ref) / 2;
    upload_line($verts_ref);
    glUniform4f($u_color, $r, $g, $b, $a);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, $n);
}

# Map [0,1] to NDC [-1,1] with padding
sub nx { -1 + 2 * ($PAD + $_[0] * (1 - 2 * $PAD)) }
sub ny { -1 + 2 * ($PAD + $_[0] * (1 - 2 * $PAD)) }

sub display {
    my $t = time();
    my $since = $t - $last_switch;

    # State machine: hold -> morph -> hold -> morph ...
    if (!$morphing && $since > $hold_duration) {
        $morphing = 1;
        $morph_start = $t;
        $next_idx = ($active_idx + 1) % @curves;
    }
    if ($morphing && ($t - $morph_start) >= $morph_duration) {
        $morphing = 0;
        $active_idx = $next_idx;
        $last_switch = $t;
    }

    # Compute morph mix (0 = current, 1 = next)
    my $mix = 0;
    if ($morphing) {
        $mix = ($t - $morph_start) / $morph_duration;
        $mix = $mix * $mix * (3 - 2 * $mix);  # smoothstep
    }

    # Interpolate sample buffers
    my @va = @{$curves[$active_idx]{vals}};
    my @vb = @{$curves[$morphing ? $next_idx : $active_idx]{vals}};
    @morph_vals = ();
    for my $i (0 .. $#va) {
        push @morph_vals, $va[$i] * (1 - $mix) + $vb[$i] * $mix;
    }

    # Blend colors
    my $ca = $curves[$active_idx];
    my $cb = $curves[$morphing ? $next_idx : $active_idx];
    my $mr = $ca->{r} * (1 - $mix) + $cb->{r} * $mix;
    my $mg = $ca->{g} * (1 - $mix) + $cb->{g} * $mix;
    my $mb = $ca->{b} * (1 - $mix) + $cb->{b} * $mix;

    # Advance phase continuously based on current blended duration
    my $dur = $curves[$active_idx]{env}->duration * (1 - $mix)
            + $curves[$morphing ? $next_idx : $active_idx]{env}->duration * $mix;
    $dur = 1 if $dur <= 0;
    my $dt = $t - $last_t;
    $last_t = $t;
    $phase_accum += $dt / $dur;
    $phase_accum -= int($phase_accum) if $phase_accum >= 1;
    my $phase = $phase_accum;
    my $val_idx = int($phase * $#morph_vals + 0.5);
    $val_idx = $#morph_vals if $val_idx > $#morph_vals;
    my $val = $morph_vals[$val_idx];

    glClearColor(0.06, 0.06, 0.09, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram($prog);

    # Grid
    for my $i (0 .. 10) {
        my $f = $i / 10;
        my $x = nx($f);
        my $y = ny($f);
        my $a = ($i == 0 || $i == 10) ? 0.2 : 0.06;
        draw_line_strip([
            $x, ny(0), $x, ny(1)
        ], 1, 1, 1, $a, 0.5);
        draw_line_strip([
            nx(0), $y, nx(1), $y
        ], 1, 1, 1, $a, 0.5);
    }

    # Draw background envelopes (faded)
    for my $ci (0 .. $#curves) {
        my $c = $curves[$ci];
        my @v = @{$c->{vals}};
        my $is_src = ($ci == $active_idx);
        my $is_dst = ($morphing && $ci == $next_idx);
        my $alpha = ($is_src || $is_dst) ? 0.15 : 0.05;

        my @line;
        for my $i (0 .. $#v) {
            push @line, nx($i / $#v), ny($v[$i]);
        }
        draw_line_strip(\@line, $c->{r}, $c->{g}, $c->{b}, $alpha, 1.0);
    }

    # Draw morphed envelope (prominent)
    {
        my @fill;
        for my $i (0 .. $#morph_vals) {
            my $x = nx($i / $#morph_vals);
            push @fill, $x, ny($morph_vals[$i]), $x, ny(0);
        }
        draw_triangle_strip(\@fill, $mr, $mg, $mb, 0.1);

        my @line;
        for my $i (0 .. $#morph_vals) {
            push @line, nx($i / $#morph_vals), ny($morph_vals[$i]);
        }
        draw_line_strip(\@line, $mr, $mg, $mb, 0.95, 2.5);
    }

    # Playhead
    my $px = nx($phase);
    draw_line_strip([$px, ny(0), $px, ny(1)], 1, 1, 0.4, 0.7, 1.5);

    # Dot (small quad)
    my $dx = 0.008;
    my $dy = $dx * $W / $H;
    my $dpx = $px;
    my $dpy = ny($val);
    draw_triangle_strip([
        $dpx - $dx, $dpy - $dy,
        $dpx - $dx, $dpy + $dy,
        $dpx + $dx, $dpy - $dy,
        $dpx + $dx, $dpy + $dy,
    ], 1, 1, 0.3, 1.0);

    # Legend (small colored quads)
    for my $ci (0 .. $#curves) {
        my $c = $curves[$ci];
        my $lx = nx(0) + 0.02;
        my $ly = ny(1) - 0.04 - $ci * 0.05;
        my $sz = 0.015;
        my $a = $ci == $active_idx ? 1.0 : 0.4;
        draw_triangle_strip([
            $lx, $ly, $lx, $ly + $sz * 2,
            $lx + $sz * 2 * $H / $W, $ly, $lx + $sz * 2 * $H / $W, $ly + $sz * 2,
        ], $c->{r}, $c->{g}, $c->{b}, $a);
    }

    glDisableVertexAttribArray(0);
    glutSwapBuffers();
}

sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

# Main
glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_MULTISAMPLE);
glutInitWindowSize($W, $H);
glutCreateWindow('Envelope Scope (OpenGL::Modern)');
init_gl();

glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "OpenGL — Press ESC to quit\n";
glutMainLoop();
