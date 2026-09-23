#!/usr/bin/env perl
# Rolling balls: balls roll along an envelope-defined slope surface
# Physics: gravity + slope gradient from envelope derivative
# No collision engine needed -- envelope IS the terrain
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

use Math::SegmentedEnvelope qw(spline env);
use Time::HiRes qw(time);
use POSIX qw(tan floor);

my $W = 900;
my $H = 650;
my $PI = 3.14159265358979323846;

# Slope profiles: different terrains the balls roll on
my @slopes = (
    spline([0, 0.15, 0.3, 0.5, 0.65, 0.8, 1.0],
           [0.9, 0.7, 0.85, 0.4, 0.6, 0.2, 0.05], resolution => 16),
    spline([0, 0.1, 0.25, 0.4, 0.55, 0.7, 0.85, 1.0],
           [0.95, 0.5, 0.8, 0.3, 0.7, 0.15, 0.4, 0.02], resolution => 16),
    env([[1.0, 0.6, 0.8, 0.3, 0.5, 0.1], [0.2, 0.2, 0.2, 0.2, 0.2],
         [-2, 2, -3, 2, -2]], morpher_formula => 'smoothstep'),
);
my $current_slope = 0;
my $slope_switch = 0;

# Physics constants
my $gravity = 2.5;
my $friction = 0.985;
my $bounce = 0.6;
my $ball_radius = 0.015;

# Balls
my $num_balls = 12;
my @balls;

sub spawn_balls {
    @balls = ();
    for my $i (0 .. $num_balls - 1) {
        push @balls, {
            x   => 0.02 + rand() * 0.15,  # start position along slope [0,1]
            vx  => 0.01 + rand() * 0.02,  # initial velocity
            r   => $ball_radius * (0.7 + rand() * 0.6),
            hue => $i / $num_balls,
            trail => [],
        };
    }
}
spawn_balls();

# Pre-compute slope data
my $slope_samples = 200;
my @slope_heights;
my @slope_gradients;

sub update_slope {
    my $e = $slopes[$current_slope];
    my $d = $e->duration;
    my $s = $e->static;
    my $deriv = $e->resample($slope_samples)->derivative->static;
    my $dd = $e->resample($slope_samples)->derivative->duration;
    @slope_heights = ();
    @slope_gradients = ();
    for my $i (0 .. $slope_samples) {
        my $t = $i / $slope_samples;
        push @slope_heights, $s->($t * $d);
        push @slope_gradients, $deriv->($t * $dd);
    }
}
update_slope();

sub slope_at {
    my ($x) = @_;
    $x = 0 if $x < 0; $x = 1 if $x > 1;
    my $fi = $x * $slope_samples;
    my $i = int($fi);
    $i = $slope_samples - 1 if $i >= $slope_samples;
    my $f = $fi - $i;
    my $next = $i < $slope_samples ? $i + 1 : $i;
    return $slope_heights[$i] * (1 - $f) + $slope_heights[$next] * $f;
}

sub gradient_at {
    my ($x) = @_;
    $x = 0 if $x < 0; $x = 1 if $x > 1;
    my $fi = $x * $slope_samples;
    my $i = int($fi);
    $i = $slope_samples - 1 if $i >= $slope_samples;
    my $f = $fi - $i;
    my $next = $i < $slope_samples ? $i + 1 : $i;
    return $slope_gradients[$i] * (1 - $f) + $slope_gradients[$next] * $f;
}

# Shaders
my $vert_src = <<'GLSL';
#version 150
in vec2 aPos;
uniform mat4 uMVP;
void main() { gl_Position = uMVP * vec4(aPos, 0.0, 1.0); }
GLSL

my $frag_src = <<'GLSL';
#version 150
uniform vec4 uColor;
out vec4 outColor;
void main() { outColor = uColor; }
GLSL

my ($prog, $u_mvp, $u_color, $vbo, $vao);
my ($start, $last_time);

sub compile_shader {
    my ($type, $src) = @_;
    my $s = glCreateShader($type);
    glShaderSource_p($s, $src);
    glCompileShader($s);
    my ($ok) = glGetShaderiv_p($s, GL_COMPILE_STATUS);
    die "Shader: " . glGetShaderInfoLog_p($s) unless $ok;
    return $s;
}

sub draw_line_strip {
    my ($verts, $r, $g, $b, $a, $width) = @_;
    $width //= 2;
    my $n = @$verts / 2;
    return if $n < 2;
    my $oa = OpenGL::Array->new_list(GL_FLOAT, @$verts);
    glBindVertexArray($vao);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo);
    glBufferData_c(GL_ARRAY_BUFFER, $oa->length, $oa->ptr, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
    glUniform4f($u_color, $r, $g, $b, $a);
    glLineWidth($width);
    glDrawArrays(GL_LINE_STRIP, 0, $n);
    glBindVertexArray(0);
}

sub draw_triangle_fan {
    my ($verts, $r, $g, $b, $a) = @_;
    my $n = @$verts / 2;
    my $oa = OpenGL::Array->new_list(GL_FLOAT, @$verts);
    glBindVertexArray($vao);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo);
    glBufferData_c(GL_ARRAY_BUFFER, $oa->length, $oa->ptr, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
    glUniform4f($u_color, $r, $g, $b, $a);
    glDrawArrays(GL_TRIANGLE_FAN, 0, $n);
    glBindVertexArray(0);
}

sub hsv {
    my ($h,$s,$v) = @_;
    $h = ($h - floor($h)) * 6; my $f = $h - floor($h);
    my $p=$v*(1-$s); my $q=$v*(1-$s*$f); my $t=$v*(1-$s*(1-$f));
    my @c=([$v,$t,$p],[$q,$v,$p],[$p,$v,$t],[$p,$q,$v],[$t,$p,$v],[$v,$p,$q]);
    @{$c[int($h)%6]};
}

sub init_gl {
    my $vs = compile_shader(GL_VERTEX_SHADER, $vert_src);
    my $fs = compile_shader(GL_FRAGMENT_SHADER, $frag_src);
    $prog = glCreateProgram();
    glAttachShader($prog, $vs);
    glAttachShader($prog, $fs);
    glBindAttribLocation($prog, 0, 'aPos');
    glLinkProgram($prog);
    my ($ok) = glGetProgramiv_p($prog, GL_LINK_STATUS);
    die "Link: " . glGetProgramInfoLog_p($prog) unless $ok;
    glDeleteShader($vs); glDeleteShader($fs);
    $u_mvp = glGetUniformLocation($prog, 'uMVP');
    $u_color = glGetUniformLocation($prog, 'uColor');

    ($vao) = glGenVertexArrays_p(1);
    ($vbo) = glGenBuffers_p(1);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_LINE_SMOOTH);

    $start = time();
    $last_time = $start;
}

sub display {
    my $now = time();
    my $dt = $now - $last_time;
    $dt = 0.033 if $dt > 0.033;  # cap delta
    $last_time = $now;
    my $t = $now - $start;

    # Switch slopes periodically
    if ($t - $slope_switch > 8) {
        $current_slope = ($current_slope + 1) % @slopes;
        update_slope();
        spawn_balls();
        $slope_switch = $t;
    }

    # Physics update
    for my $ball (@balls) {
        my $grad = gradient_at($ball->{x});
        # slope angle -> acceleration along x
        my $angle = atan2($grad, 1);
        my $ax = $gravity * sin($angle) * $dt;
        # Negative gradient means downhill in +x direction for our setup
        $ball->{vx} -= $ax;
        $ball->{vx} *= $friction;

        $ball->{x} += $ball->{vx} * $dt;

        # Bounce off walls
        if ($ball->{x} < 0) {
            $ball->{x} = 0;
            $ball->{vx} = abs($ball->{vx}) * $bounce;
        }
        if ($ball->{x} > 1) {
            $ball->{x} = 1;
            $ball->{vx} = -abs($ball->{vx}) * $bounce;
        }

        # Trail
        my $h = slope_at($ball->{x});
        push @{$ball->{trail}}, [$ball->{x}, $h + $ball->{r}];
        shift @{$ball->{trail}} while @{$ball->{trail}} > 40;
    }

    # Render
    glClearColor(0.06, 0.08, 0.12, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram($prog);

    # Simple ortho-like projection mapping [0,1] x [0,1] to NDC
    my @mvp = (0) x 16;
    $mvp[0] = 2 * 0.9;  $mvp[12] = -1 + 0.05 * 2;  # x: [0,1] -> [-0.9, 0.9]
    $mvp[5] = 2 * 0.8;  $mvp[13] = -1 + 0.1 * 2;    # y: [0,1] -> [-0.8, 0.8]
    $mvp[10] = 1; $mvp[15] = 1;
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);

    # Draw slope surface (filled)
    {
        my @fill;
        for my $i (0 .. $slope_samples) {
            my $x = $i / $slope_samples;
            push @fill, $x, $slope_heights[$i];
        }
        push @fill, 1, 0, 0, 0;  # close bottom
        draw_triangle_fan(\@fill, 0.15, 0.2, 0.25, 0.5);
    }

    # Draw slope line
    {
        my @line;
        for my $i (0 .. $slope_samples) {
            push @line, $i / $slope_samples, $slope_heights[$i];
        }
        draw_line_strip(\@line, 0.4, 0.6, 0.8, 1.0, 3);
    }

    # Draw gradient indicators (small arrows showing slope direction)
    for my $i (0 .. 9) {
        my $x = ($i + 0.5) / 10;
        my $h = slope_at($x);
        my $g = gradient_at($x);
        my $angle = atan2($g, 1);
        my $len = 0.03;
        my $dx = cos($angle) * $len;
        my $dy = sin($angle) * $len;
        draw_line_strip([$x, $h + 0.01, $x + $dx, $h + 0.01 + $dy],
            0.8, 0.8, 0.2, 0.3, 1);
    }

    # Draw balls
    for my $ball (@balls) {
        my $bx = $ball->{x};
        my $bh = slope_at($bx) + $ball->{r};
        my ($cr, $cg, $cb) = hsv($ball->{hue}, 0.8, 0.8);

        # Trail
        if (@{$ball->{trail}} > 2) {
            my @trail;
            for my $pt (@{$ball->{trail}}) {
                push @trail, $pt->[0], $pt->[1];
            }
            draw_line_strip(\@trail, $cr, $cg, $cb, 0.3, 1);
        }

        # Ball (circle as triangle fan)
        my $segs = 16;
        my @circle = ($bx, $bh);
        for my $si (0 .. $segs) {
            my $a = $si / $segs * 2 * $PI;
            push @circle, $bx + cos($a) * $ball->{r} * ($H/$W),
                          $bh + sin($a) * $ball->{r};
        }
        draw_triangle_fan(\@circle, $cr, $cg, $cb, 0.9);

        # Highlight
        my @hl = ($bx - $ball->{r} * 0.3 * ($H/$W), $bh + $ball->{r} * 0.3);
        for my $si (0 .. 8) {
            my $a = $si / 8 * 2 * $PI;
            push @hl, $bx - $ball->{r} * 0.3 * ($H/$W) + cos($a) * $ball->{r} * 0.3 * ($H/$W),
                      $bh + $ball->{r} * 0.3 + sin($a) * $ball->{r} * 0.3;
        }
        draw_triangle_fan(\@hl, 1, 1, 1, 0.4);

        # Speed indicator (small line showing velocity direction)
        my $vlen = $ball->{vx} * 2;
        draw_line_strip([$bx, $bh, $bx + $vlen, $bh], $cr, $cg, $cb, 0.5, 1);
    }

    # Info
    glutSetWindowTitle(sprintf "Rolling Balls — slope %d/%d — %d balls — ESC to quit",
        $current_slope + 1, scalar @slopes, $num_balls);

    glutSwapBuffers();
}

sub idle { glutPostRedisplay() }
sub keyboard {
    my $k = ord($_[0]);
    exit(0) if $k == 27;
    # Space: respawn balls
    if ($k == 32) { spawn_balls() }
    # N: next slope
    if ($k == ord('n') || $k == ord('N')) {
        $current_slope = ($current_slope + 1) % @slopes;
        update_slope(); spawn_balls(); $slope_switch = time() - $start;
    }
}

glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_MULTISAMPLE);
glutInitWindowSize($W, $H);
glutCreateWindow('Rolling Balls');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Rolling balls: %d balls, %d slopes — Space=respawn, N=next slope, ESC=quit\n",
    $num_balls, scalar @slopes;
glutMainLoop();
