
use Gtk;

use Gtk::GLArea;
use Gtk::GLArea::Constants;
use OpenGL qw(:all);

#TITLE: Open GL Test
#REQUIRES: Gtk GtkGLArea

sub init {
	my($widget) = @_;
	
	if ($widget->begingl) {
		glViewport(0,0,$widget->allocation->[2], $widget->allocation->[3]);
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		gluOrtho2D(0,100, 100,0);
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		$widget->endgl;
	}

	#Gtk->timeout_add(100, sub { $widget->queue_draw; return 1; } );

	return 1;
}

sub draw {
	my($widget,$expose) = @_;
	
	if ($expose->{count} > 0) {
		return 1;
	}
	
	if ($widget->begingl) {
		glClearColor(0,0,0,1);
		glClear(GL_COLOR_BUFFER_BIT);
		glColor3d(.8,.6,1);
		glBegin(GL_TRIANGLES);
		glVertex2d(10,10);
		glVertex2d(10,90);
		glVertex2d(90,90);
		glEnd();
		
		$widget->endgl;
	}
	
	$widget->swapbuffers;
	
	return 1;
}

sub reshape {
	my($widget,$event) = @_;
	
	if ($widget->begingl) {
		glViewport(0,0, $widget->allocation->[2], $widget->allocation->[3]);
		$widget->endgl;
	}
	
	return 1;
}


init Gtk;

if (!Gtk::Gdk::GL->query) {
	die "OpenGL not supported";
}

$window = new Gtk::Window -toplevel;
$window->set_title("Simple");
$window->set_border_width(10);

$window->signal_connect( "delete_event" => sub { Gtk->main_quit } );


#Gtk->quit_add( 1, sub { destroy $window } );

#sub GDK_GL_RGBA { 4 }
#sub GDK_GL_DOUBLEBUFFER { 5 }
#sub GDK_GL_NONE { 0 }

$glarea = new Gtk::GLArea GDK_GL_RGBA, GDK_GL_DOUBLEBUFFER, GDK_GL_NONE;

$glarea->set_events([-exposure_mask, -button_press_mask]);

$glarea->signal_connect( "expose_event" => \&draw );
$glarea->signal_connect( "configure_event" => \&reshape );
$glarea->signal_connect( "realize" => \&init );

$glarea->set_usize(100,100);

$window->add($glarea);

show $glarea;
show $window;

Gtk->main;
