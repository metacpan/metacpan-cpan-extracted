#!/usr/bin/env perl
# OpenGL terrain visualization: spline envelope as 3D heightmap
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

use Math::SegmentedEnvelope qw(spline env);
use POSIX qw(tan);
use Time::HiRes qw(time);

srand(42);

# Generate terrain as two perpendicular spline envelopes
my $res = 64;

# X-axis height profile
my @tx = map { $_ / 7 } 0 .. 7;
my @vx = (0.2, 0.5, 0.8, 0.3, 0.9, 0.4, 0.6, 0.2);
my $terrain_x = spline(\@tx, \@vx, resolution => 12);

# Z-axis height profile (perpendicular)
my @tz = map { $_ / 5 } 0 .. 5;
my @vz = (0.3, 0.7, 0.5, 0.9, 0.4, 0.3);
my $terrain_z = spline(\@tz, \@vz, resolution => 12);

# Sample heightmap grid
my $sx = $terrain_x->static;
my $sz = $terrain_z->static;
my $dx = $terrain_x->duration;
my $dz = $terrain_z->duration;

my @heights;
for my $zi (0 .. $res - 1) {
    for my $xi (0 .. $res - 1) {
        my $hx = $sx->($xi / ($res - 1) * $dx);
        my $hz = $sz->($zi / ($res - 1) * $dz);
        $heights[$zi * $res + $xi] = ($hx + $hz) * 0.5;
    }
}

my $rotation = 0;
my $start = time();

sub height_color {
    my ($h) = @_;
    if ($h < 0.3)    { return (0.2, 0.3, 0.8) }   # water
    elsif ($h < 0.4) { return (0.8, 0.7, 0.5) }   # sand
    elsif ($h < 0.65) { return (0.2, 0.6, 0.2) }  # grass
    elsif ($h < 0.8) { return (0.5, 0.4, 0.3) }   # rock
    else              { return (0.9, 0.9, 0.95) }  # snow
}

sub display {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();

    # Camera
    my $t = time() - $start;
    my $eye_y = 2.0;
    my $eye_dist = 3.0;
    glTranslatef(0, -0.5, -$eye_dist);
    glRotatef(25, 1, 0, 0);
    glRotatef($t * 15, 0, 1, 0);  # slow rotation
    glTranslatef(-0.5, 0, -0.5);

    # Draw terrain as triangle strips
    my $scale = 1.0 / ($res - 1);
    for my $zi (0 .. $res - 2) {
        glBegin(GL_TRIANGLE_STRIP);
        for my $xi (0 .. $res - 1) {
            for my $dz (0, 1) {
                my $z = $zi + $dz;
                my $h = $heights[$z * $res + $xi];
                my ($r, $g, $b) = height_color($h);
                # Simple shading based on slope
                my $shade = 0.7 + 0.3 * $h;
                glColor3f($r * $shade, $g * $shade, $b * $shade);
                glVertex3f($xi * $scale, $h * 0.5, $z * $scale);
            }
        }
        glEnd();
    }

    # Water plane
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glColor4f(0.2, 0.3, 0.7, 0.5);
    glBegin(GL_QUADS);
    glVertex3f(0, 0.15, 0);
    glVertex3f(1, 0.15, 0);
    glVertex3f(1, 0.15, 1);
    glVertex3f(0, 0.15, 1);
    glEnd();
    glDisable(GL_BLEND);

    glutSwapBuffers();
}

sub reshape {
    my ($w, $h) = @_;
    glViewport(0, 0, $w, $h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    my $aspect = $w / ($h || 1);
    my $near = 0.1;
    my $far  = 100.0;
    my $top  = $near * tan(45 * 3.14159265 / 360);
    my $right = $top * $aspect;
    glFrustum(-$right, $right, -$top, $top, $near, $far);
    glMatrixMode(GL_MODELVIEW);
}

sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }  # ESC to quit

# Main
glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH);
glutInitWindowSize(800, 600);
glutCreateWindow("Envelope Terrain");

glEnable(GL_DEPTH_TEST);
glClearColor(0.5, 0.7, 0.9, 1.0);

glutDisplayFunc(\&display);
glutReshapeFunc(\&reshape);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Terrain: %dx%d grid from spline envelopes\n", $res, $res;
print "Press ESC to quit\n";
glutMainLoop();
