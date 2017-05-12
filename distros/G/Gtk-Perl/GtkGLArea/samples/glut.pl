#!/usr/bin/perl -w

# Just mumbling, ignore this for the moment

#use OpenGL qw(:all);

use Gtk;
use OpenGL qw(:all !:glutconstants !:glutfunctions);
use Gtk::GLArea;
use Gtk::GLArea::Glut qw(:all);
init Gtk;

use Data::Dumper;

$M_PI = 3.14159265;

#  Draw a gear wheel.  You'll probably want to call this function when
#  building a display list since we do a lot of trig here.
# 
#  Input:  inner_radius - radius of hole at center
#          outer_radius - radius at center of teeth
#          width - width of gear
#          teeth - number of teeth
#          tooth_depth - depth of tooth

sub im {

	my($w) =  glutGet ( GLUT_WINDOW_WIDTH ) ;
	my($h) =  glutGet ( GLUT_WINDOW_HEIGHT ) ;
	
  glPushAttrib   ( GL_ENABLE_BIT | GL_VIEWPORT_BIT | GL_TRANSFORM_BIT | GL_COLOR_BUFFER_BIT) ;
  glDisable      ( GL_LIGHTING   ) ;
  glDisable      ( GL_FOG        ) ;
  glDisable      ( GL_TEXTURE_2D ) ;
  glDisable      ( GL_DEPTH_TEST ) ;
  glDisable      ( GL_CULL_FACE  ) ;
  glDisable	 ( GL_STENCIL_TEST );
 
  glViewport     ( 0, 0, $w, $h ) ;
  glMatrixMode   ( GL_PROJECTION ) ;
  glPushMatrix   () ;
  glLoadIdentity () ;
  gluOrtho2D     ( 0, $w, 0, $h ) ;
  glMatrixMode   ( GL_MODELVIEW ) ;
  glPushMatrix   () ;
  glLoadIdentity () ;
  
  glPixelZoom(1, 1);
  
  @p =  glReadPixels_p(30, 30, 40, 40, GL_RGB, GL_UNSIGNED_INT);
  glRasterPos2f(10, 10);
  glDrawPixels_p(40, 40, GL_RGB, GL_UNSIGNED_INT, @p);

  glMatrixMode   ( GL_PROJECTION ) ;
  glPopMatrix    () ;
  glMatrixMode   ( GL_MODELVIEW ) ;
  glPopMatrix    () ;
  glPopAttrib    () ;
	
}

sub gear
{
	my($inner_radius, $outer_radius, $width, $teeth, $tooth_depth) = @_;
	my($i,$r0,$r1,$r2,$angle, $da,$u,$v,$len);
	
	$r0 = $inner_radius;
	$r1 = $outer_radius - $tooth_depth / 2.0;
	$r2 = $outer_radius + $tooth_depth / 2.0;
	
	$da = 2.0 * $M_PI / $teeth / 4.0;
	
	glShadeModel(GL_FLAT);
	
	glNormal3f(0.0, 0.0, 1.0);
	
	glBegin(GL_QUAD_STRIP);
	for ($i = 0; $i <= $teeth; $i++) {
		$angle = $i * 2.0 * $M_PI / $teeth;
		glVertex3d($r0 * cos($angle), $r0 * sin($angle), $width * 0.5);
		glVertex3d($r1 * cos($angle), $r1 * sin($angle), $width * 0.5);
		glVertex3d($r0 * cos($angle), $r0 * sin($angle), $width * 0.5);
		glVertex3d($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da), $width * 0.5);
	}
	glEnd();
	
	glBegin(GL_QUADS);
	$da = 2.0 * $M_PI / $teeth / 4.0;
	for ($i = 0; $i <= $teeth; $i++) {
		$angle = $i * 2.0 * $M_PI / $teeth;
		glVertex3d($r1 * cos($angle), $r1 * sin($angle), $width * 0.5);
		glVertex3d($r2 * cos($angle+$da), $r2 * sin($angle+$da), $width * 0.5);
		glVertex3d($r2 * cos($angle+2*$da), $r2 * sin($angle+2*$da), $width * 0.5);
		glVertex3d($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da), $width * 0.5);
	}
	glEnd();
	
	glNormal3d(0.0, 0.0, -1.0);
	
	glBegin(GL_QUAD_STRIP);
	for ($i = 0; $i <= $teeth; $i++) {
		$angle = $i * 2.0 * $M_PI / $teeth;
		glVertex3d($r1 * cos($angle), $r1 * sin($angle), -$width * 0.5);
		glVertex3d($r0 * cos($angle), $r0 * sin($angle), -$width * 0.5);
		glVertex3d($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da), -$width * 0.5);
		glVertex3d($r0 * cos($angle), $r0 * sin($angle), -$width * 0.5);
	}
	glEnd();
	
	glBegin(GL_QUADS);
	$da = 2.0 * $M_PI / $teeth / 4.0;
	for ($i = 0; $i <= $teeth; $i++) {
		$angle = $i * 2.0 * $M_PI / $teeth;
		glVertex3d($r1 * cos($angle+3*$da), $r1 * sin($angle+3*$da), -$width * 0.5);
		glVertex3d($r2 * cos($angle+2*$da), $r2 * sin($angle+2*$da), -$width * 0.5);
		glVertex3d($r2 * cos($angle+$da), $r2 * sin($angle+$da), -$width * 0.5);
		glVertex3d($r1 * cos($angle), $r1 * sin($angle), -$width * 0.5);
	}
	glEnd();


 # /* draw outward faces of teeth */
  glBegin(GL_QUAD_STRIP);
  for ($i = 0; $i < $teeth; $i++) {
    $angle = $i * 2.0 * $M_PI / $teeth;

    glVertex3d($r1 * cos($angle), $r1 * sin($angle), $width * 0.5);
    glVertex3d($r1 * cos($angle), $r1 * sin($angle), -$width * 0.5);
    $u = $r2 * cos($angle + $da) - $r1 * cos($angle);
    $v = $r2 * sin($angle + $da) - $r1 * sin($angle);
    $len = sqrt($u * $u + $v * $v);
    $u /= $len;
    $v /= $len;
    glNormal3d($v, -$u, 0.0);
    glVertex3d($r2 * cos($angle + $da), $r2 * sin($angle + $da), $width * 0.5);
    glVertex3d($r2 * cos($angle + $da), $r2 * sin($angle + $da), -$width * 0.5);
    glNormal3d(cos($angle), sin($angle), 0.0);
    glVertex3d($r2 * cos($angle + 2 * $da), $r2 * sin($angle + 2 * $da), $width * 0.5);
    glVertex3d($r2 * cos($angle + 2 * $da), $r2 * sin($angle + 2 * $da), -$width * 0.5);
    $u = $r1 * cos($angle + 3 * $da) - $r2 * cos($angle + 2 * $da);
    $v = $r1 * sin($angle + 3 * $da) - $r2 * sin($angle + 2 * $da);
    glNormal3d($v, -$u, 0.0);
    glVertex3d($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da), $width * 0.5);
    glVertex3d($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da), -$width * 0.5);
    glNormal3d(cos($angle), sin($angle), 0.0);
  }

  glVertex3d($r1 * cos(0), $r1 * sin(0), $width * 0.5);
  glVertex3d($r1 * cos(0), $r1 * sin(0), -$width * 0.5);

  glEnd();

  glShadeModel(GL_SMOOTH);

# draw inside radius cylinder */
  glBegin(GL_QUAD_STRIP);
  for ($i = 0; $i <= $teeth; $i++) {
    $angle = $i * 2.0 * $M_PI / $teeth;
    glNormal3d(-cos($angle), -sin($angle), 0.0);
    glVertex3d($r0 * cos($angle), $r0 * sin($angle), -$width * 0.5);
    glVertex3d($r0 * cos($angle), $r0 * sin($angle), $width * 0.5);
  }
  glEnd();

}


$view_rotx = 20.0; $view_roty = 30.0; $view_rotz = 0.0;
$angle = 0.0;

$count = 1;

sub draw {
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  glPushMatrix();
  glRotated($view_rotx, 1.0, 0.0, 0.0);
  glRotated($view_roty, 0.0, 1.0, 0.0);
  glRotated($view_rotz, 0.0, 0.0, 1.0);

  glPushMatrix();
  glTranslated(-3.0, -2.0, 0.0);
  glRotated($angle, 0.0, 0.0, 1.0);
  glCallList($gear1);
  glPopMatrix();

  glPushMatrix();
  glTranslated(3.1, -2.0, 0.0);
  glRotated(-2.0 * $angle - 9.0, 0.0, 0.0, 1.0);
  glCallList($gear2);
  glPopMatrix();

  glPushMatrix();
  glTranslated(-3.1, 4.2, 0.0);
  glRotated(-2.0 * $angle - 25.0, 0.0, 0.0, 1.0);
  glCallList($gear3);
  glPopMatrix();



  glPopMatrix();
  
  im;
#  
#	@p = glReadPixels_p(55, 55, 2, 2, GL_RGB, GL_UNSIGNED_BYTE);
#	print join('|',@p),"\n";
#
#	glRasterPos2i(75, 85);
#	glDrawPixels_p(2, 2, GL_RGB, GL_UNSIGNED_BYTE, \@p);

  glutSwapBuffers();


  $count++;
  if ($count == $limit) {
    exit(0);
  }
}

sub idle(void)
{
  $angle += 2.0;
  glutSetWindow($win1);
  glutPostRedisplay();
  glutSetWindow($win2);
  glutPostRedisplay();
}

#/* change view angle, exit upon ESC */
sub key {
	my($k,$x,$y) = @_;

	if ($k == ord('z')) {
		$view_rotz += 5.0;
	} elsif ($k == ord('Z')) {
		$view_rotz -= 5.0;
	} elsif ($k == 27) {
		exit(0);
	} else {
		return;
	}

  glutPostRedisplay();
}

#/* change view angle */
sub special {
	my($k,$x,$y) = @_;
	
	if ($k == GLUT_KEY_UP) {
		$view_rotx += 5.0;
	} elsif ($k == GLUT_KEY_DOWN) {
		$view_rotx -= 5.0;
	} elsif ($k == GLUT_KEY_LEFT) {
		$view_roty += 5.0;
	} elsif ($k == GLUT_KEY_RIGHT) {
		$view_roty -= 5.0;
	} else {
		return;
	}
	glutPostRedisplay();

}

sub reshape {
	print "reshape: @_\n";
	my($width, $height) = @_;
	my($h) = $height / $width;

  glViewport(0, 0, $width, $height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glFrustum(-1.0, 1.0, -$h, $h, 5.0, 60.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glTranslated(0.0, 0.0, -40.0);
}

sub init {
	my(@pos) = (5.0, 5.0, 10.0, 0.0);
	my(@red) = (0.8, 0.1, 0.0, 1.0);
	my(@green) = (0.0, 0.8, 0.2, 1.0);
	my(@blue) = (0.2, 0.2, 1.0, 1.0);

  glLightfv_p(GL_LIGHT0, GL_POSITION, @pos);
  glEnable(GL_CULL_FACE);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glEnable(GL_DEPTH_TEST);

#  /* make the gears */
  $gear1 = glGenLists(1);
  glNewList($gear1, GL_COMPILE);
  glMaterialfv_p(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @red);
  gear(1.0, 4.0, 1.0, 20, 0.7);
  glEndList();

  $gear2 = glGenLists(1);
  glNewList($gear2, GL_COMPILE);
  glMaterialfv_p(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @green);
  gear(0.5, 2.0, 2.0, 10, 0.7);
  glEndList();

  $gear3 = glGenLists(1);
  glNewList($gear3, GL_COMPILE);
  glMaterialfv_p(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @blue);
  gear(1.3, 2.0, 0.5, 10, 0.7);
  glEndList();

  glEnable(GL_NORMALIZE);
}

sub visible {
	my($vis) = @_;

  if ($vis == GLUT_VISIBLE) {
    glutIdleFunc(\&idle);
  } else {
    glutIdleFunc(undef);
  }
}


glutInit();

if (@ARGV) {
#    /* do 'n' frames then exit */
    $limit = $ARGV[0] + 1;
} else {
    $limit = 0;
}

glutInitDisplayMode(GLUT_RGB | GLUT_DEPTH | GLUT_DOUBLE);

glutInitWindowPosition(0, 0);
glutInitWindowSize(300, 300);
$win1 = glutCreateWindow("Gears");
init();

glutCreateMenu(sub { print "Menu callback: ",@_,"\n" });
glutAddMenuEntry("Bargable", 1);
glutAddMenuEntry("Foogly", 2);

glutAttachMenu(1);

glutMenuStateFunc(sub { print "menustate: ", Dumper(\@_) });
glutDisplayFunc(\&draw);
glutReshapeFunc(\&reshape);
#glutKeyboardFunc(\&key);
#glutSpecialFunc(\&special);
glutVisibilityFunc(\&visible);
glutIdleFunc(\&idle);
    
$win2 = glutCreateSubWindow(glutGetWindow(), 100, 100, 100, 100);
#$win2 = glutCreateWindow("goo");
init();
glutAttachMenu(2);
glutDisplayFunc(\&draw);
glutReshapeFunc(\&reshape);
#glutKeyboardFunc(\&key);
#glutSpecialFunc(\&special);
glutVisibilityFunc(\&visible);
#glutIdleFunc(\&idle);

#glutMouseFunc(sub {
#	print "m\n";
#	@p = glReadPixels_p(20, 20, 20, 20, GL_RGB, GL_INT);
#	print join("|", @p),"\n";
#});
#
#
glutMainLoop();
