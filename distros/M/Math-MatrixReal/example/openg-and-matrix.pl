#!/usr/bin/env perl
use 5.12.0;
use strict;
use warnings;

use OpenGL qw/:all/;
use AntTweakBar qw/:all/;
use AntTweakBar::Type;
use List::MoreUtils qw/pairwise/;
use List::Util qw/reduce/;
use Math::MatrixReal;
use Math::Trig;
use Data::Dump qw/dump/;
use Time::HiRes qw/tv_interval gettimeofday/;

sub display;

sub reshape {
    my ($width, $height) = @_;
    glViewport(0, 0, $width, $height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    gluPerspective(40, $width/$height, 1, 10);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity;
    gluLookAt(0,0,5, 0,0,0, 0,1,0);
    glTranslatef(0, 0.6, -1);

    AntTweakBar::window_size($width, $height);
}


glutInit;
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
glutInitWindowSize(640, 480);
glutCreateWindow("Math::MatrixReal");

AntTweakBar::init(TW_OPENGL);

glutDisplayFunc(\&display);
glutReshapeFunc(\&reshape);
glutMouseFunc(\&AntTweakBar::eventMouseButtonGLUT);
glutMotionFunc(\&AntTweakBar::eventMouseMotionGLUT);
glutPassiveMotionFunc(\&AntTweakBar::eventMouseMotionGLUT);
glutKeyboardFunc(\&AntTweakBar::eventKeyboardGLUT);
glutSpecialFunc(\&AntTweakBar::eventSpecialGLUT);
#AntTweakBar::GLUTModifiersFunc(\&glutGetModifiers);

reshape(640, 750);

# variables
my $zoom             = 1.0;
my $angle            = 0.0;
my $axis             = [ 0.0, 0.0, 1.0 ];
my $light_multiplier = 1.0;
my $light_direction  = [ -0.57735, -0.57735, -0.57735 ];
my $material_ambient = [ 0.5, 0.0, 0.0];
my $material_diffuse = [ 1.0, 1.0, 0.0];
my $current_matrix   = ~(rotation_matrix($axis, $angle));

my $shape_id = 1;
glNewList($shape_id, GL_COMPILE);
glutSolidTeapot(1.0);
glEndList;

sub rotation_matrix {
    my ($axis, $angle) = @_;
    my ($x, $y, $z) = @$axis;
    my $f = $angle;
    my $cos_f = cos(deg2rad($f));
    my $sin_f = sin(deg2rad($f));
    my $rotation = Math::MatrixReal->new_from_rows([
        [$cos_f+(1-$cos_f)*$x**2,    (1-$cos_f)*$x*$y-$sin_f*$z, (1-$cos_f)*$x*$z+$sin_f*$y, 0 ],
        [(1-$cos_f)*$y*$z+$sin_f*$z, $cos_f+(1-$cos_f)*$y**2 ,   (1-$cos_f)*$y*$z-$sin_f*$x, 0 ],
        [(1-$cos_f)*$z*$x-$sin_f*$y, (1-$cos_f)*$z*$y+$sin_f*$x, $cos_f+(1-$cos_f)*$z**2    ,0 ],
        [0,                          0,                          0,                          1 ],
    ]);
}

sub display {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glEnable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glEnable(GL_NORMALIZE);

    # set light
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    my $ambient_light = OpenGL::Array->new_list(
        GL_FLOAT, (0.4 * $light_multiplier) x 3, 1.0);
    my $diffuse_light = OpenGL::Array->new_list(
        GL_FLOAT, (0.8 * $light_multiplier) x 3, 1.0);
    glLightfv_c(GL_LIGHT0, GL_AMBIENT, $ambient_light->ptr);
    glLightfv_c(GL_LIGHT0, GL_DIFFUSE, $diffuse_light->ptr);
    my $light_position = OpenGL::Array->new_list(
        GL_FLOAT, map { $_ * -1 } @$light_direction, 0.0);
    glLightfv_c(GL_LIGHT0, GL_POSITION, $light_position->ptr);

    # set material
    my $oga_material_ambient = OpenGL::Array->new_list(
        GL_FLOAT, @$material_ambient);
    my $oga_material_diffuse = OpenGL::Array->new_list(
        GL_FLOAT, @$material_diffuse);
    glMaterialfv_c(GL_FRONT_AND_BACK, GL_AMBIENT, $oga_material_ambient->ptr);
    glMaterialfv_c(GL_FRONT_AND_BACK, GL_DIFFUSE, $oga_material_diffuse->ptr);

    # Rotate and draw shape
    glPushMatrix;
    {
        glMultMatrixf_p($current_matrix->as_list);
        glTranslatef(0.5, -0.3, 0.0);
        glCallList($shape_id); # shape_id = shape + 1
    }
    glPopMatrix;

    AntTweakBar::draw;
    glutSwapBuffers;
    glutPostRedisplay;
}

my $bar = AntTweakBar->new(
    "Math::MatrixReal",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "axis",
    type       => 'direction',
    value      => \$axis,
    definition => " opened=true label='Rotation axis' ",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "angle_rw",
    type       => 'integer',
    cb_read    => sub { $angle },
    cb_write   => sub {
        $angle = shift;
        # normalizing rotation axis
        my $length = reduce { $a + $b } map { $_ * $_ } @$axis;
        my $normal = [0.0, 0.0, 1.0];
        if($length) {
            $normal->[$_] = $axis->[$_] / $length  for(0 .. @$axis-1);
        }
        $current_matrix   = ~(rotation_matrix($normal, $angle));
    },
    definition => " label='angle' max=359 min=0",
);

glutMainLoop;
