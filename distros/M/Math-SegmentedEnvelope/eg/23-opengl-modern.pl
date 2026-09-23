#!/usr/bin/env perl
# OpenGL::Modern integration: envelope-driven shader uniforms for animation
# Demonstrates using envelopes as control signals for real-time graphics
#
# Requires: OpenGL::Modern, OpenGL::GLUT (or similar)
use strict;
use warnings;

BEGIN {
    eval { require OpenGL::Modern; OpenGL::Modern->import(':all'); 1 }
        or die "This example requires OpenGL::Modern (install via: cpanm OpenGL::Modern)\n";
    eval { require OpenGL::GLUT; OpenGL::GLUT->import(':all'); 1 }
        or die "This example requires OpenGL::GLUT (install via: cpanm OpenGL::GLUT)\n";
}

use Math::SegmentedEnvelope qw(env adsr perc spline);
use Time::HiRes qw(time);

# Animation envelopes
my $pulse     = env([[1.0, 1.3, 1.0], [0.3, 0.7], [-3, 2]],
                    is_morph => 1, morpher_formula => 'elastic_out',
                    is_fold_over => 1);
my $fade      = adsr(0.5, 0.3, 0.8, 1.0, morpher_formula => 'smoothstep');
my $color_hue = spline([0, 0.25, 0.5, 0.75, 1.0],
                       [0, 0.3, 0.6, 0.9, 1.0],
                       resolution => 8, is_fold_over => 1);
my $shake     = perc(0.01, 0.3, peak => 0.05);

# Pre-compile static evaluators for render loop performance
my $pulse_s = $pulse->static;
my $fade_s  = $fade->static;
my $hue_s   = $color_hue->static;
my $shake_s = $shake->static;

# Pre-generate lookup tables for GPU upload
my $table_size = 256;
my @pulse_lut = $pulse->table($table_size);
my @fade_lut  = $fade->table($table_size);

my $start_time;

sub init {
    glClearColor(0.1, 0.1, 0.15, 1.0);
    $start_time = time();

    # Upload envelope LUT as 1D texture (for shader sampling)
    my @tex_data = map { int($_ * 255 + 0.5) } @fade_lut;
    # glGenTextures, glTexImage1D, etc. would go here

    print "OpenGL initialized. Envelope LUTs uploaded.\n";
    printf "  pulse: %d table entries, dur=%.2fs\n", scalar @pulse_lut, $pulse->duration;
    printf "  fade:  %d table entries, dur=%.2fs\n", scalar @fade_lut, $fade->duration;
}

sub display {
    my $t = time() - $start_time;

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    # Sample envelopes at current time
    my $scale = $pulse_s->($t);
    my $alpha = $fade_s->($t);
    my $hue   = $hue_s->($t);
    my $shake_x = $shake_s->($t) * sin($t * 30);
    my $shake_y = $shake_s->($t) * cos($t * 25);

    # HSV to RGB for the hue envelope
    my ($r, $g, $b) = hsv2rgb($hue, 0.8, 1.0);

    # Apply to OpenGL state
    glPushMatrix();
    glTranslatef($shake_x, $shake_y, 0);
    glScalef($scale, $scale, 1.0);
    glColor4f($r, $g, $b, $alpha);

    # Draw a simple quad (placeholder for real geometry)
    glBegin(GL_QUADS);
    glVertex2f(-0.5, -0.5);
    glVertex2f( 0.5, -0.5);
    glVertex2f( 0.5,  0.5);
    glVertex2f(-0.5,  0.5);
    glEnd();

    glPopMatrix();
    glutSwapBuffers();

    # For shader-based rendering, you would set uniforms:
    #   glUniform1f($u_scale, $scale);
    #   glUniform1f($u_alpha, $alpha);
    #   glUniform3f($u_color, $r, $g, $b);
    #   glUniform1i($u_envelope_tex, 0);  # sampler for LUT texture
}

sub idle {
    glutPostRedisplay();
}

sub hsv2rgb {
    my ($h, $s, $v) = @_;
    $h = ($h - int($h)) * 6.0;
    my $f = $h - int($h);
    my $p = $v * (1 - $s);
    my $q = $v * (1 - $s * $f);
    my $t = $v * (1 - $s * (1 - $f));
    my @rgb = (
        [$v, $t, $p], [$q, $v, $p], [$p, $v, $t],
        [$p, $q, $v], [$t, $p, $v], [$v, $p, $q],
    );
    return @{$rgb[int($h) % 6]};
}

# Main
glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH);
glutInitWindowSize(800, 600);
glutCreateWindow("Envelope-Driven OpenGL Animation");
init();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
print "Starting render loop (Ctrl+C to quit)...\n";
glutMainLoop();
