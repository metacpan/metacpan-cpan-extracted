#! /usr/bin/perl

#
# button.c:
# Simple toggle button example.
#
# written by Naofumi Yasufuku  <naofumi@users.sourceforge.net>
#
#
# Translated to perl by B. Steinsbo, steinsbo@users.sourceforge.net
# Minimal changes (no re-write to "perlish" perl) so that users can easily
# recognize the original.

use strict;
use Gtk2 '-init';
use Gtk2::GLExt;
use OpenGL qw/:all/;
use Data::Dumper;

use constant TIMEOUT_INTERVAL => 10;
use constant G_PI => (atan2(1.0, 1.0) * 4);

my $animate = 1;

my $angle = 0.0;
my $pos_y = 0.0;

sub realize {
  my ($widget, $data) = @_;

  my $glcontext = $widget->get_gl_context;
  my $gldrawable = $widget->get_gl_drawable;

  my @ambient = ( 0.0, 0.0, 0.0, 1.0 );
  my @diffuse = ( 1.0, 1.0, 1.0, 1.0 );
  my @position = ( 1.0, 1.0, 1.0, 0.0 );
  my @lmodel_ambient = ( 0.2, 0.2, 0.2, 1.0 );
  my @local_view = ( 0.0 );

  ### OpenGL BEGIN ###
  return unless $gldrawable->gl_begin ($glcontext);

  glLightfv_p (GL_LIGHT0, GL_AMBIENT, @ambient);
  glLightfv_p (GL_LIGHT0, GL_DIFFUSE, @diffuse);
  glLightfv_p (GL_LIGHT0, GL_POSITION, @position);
  glLightModelfv_p (GL_LIGHT_MODEL_AMBIENT, @lmodel_ambient);
  glLightModelfv_p (GL_LIGHT_MODEL_LOCAL_VIEWER, @local_view);
  glEnable (GL_LIGHTING);
  glEnable (GL_LIGHT0);
  glEnable (GL_DEPTH_TEST);

  glClearColor (1.0, 1.0, 1.0, 1.0);
  glClearDepth (1.0);

  $gldrawable->gl_end;
  ### OpenGL END ###
}

sub configure_event {
  my ($widget, $event, $data) = @_;

  my $glcontext = $widget->get_gl_context;
  my $gldrawable = $widget->get_gl_drawable;

  my $w = $widget->allocation->width;
  my $h = $widget->allocation->height;
  my $aspect;

  ### OpenGL BEGIN ###
  return 0 unless $gldrawable->gl_begin ($glcontext);

  glViewport (0, 0, $w, $h);

  glMatrixMode (GL_PROJECTION);
  glLoadIdentity ();
  if ($w > $h)
    {
      $aspect = $w / $h;
      glFrustum (-$aspect, $aspect, -1.0, 1.0, 5.0, 60.0);
    }
  else
    {
      $aspect = $h / $w;
      glFrustum (-1.0, 1.0, -$aspect, $aspect, 5.0, 60.0);
    }

  glMatrixMode (GL_MODELVIEW);

  $gldrawable->gl_end;
  ### OpenGL END ###

  return 1;
}

sub expose_event {
  my ($widget, $event, $data) = @_;

  my $glcontext = $widget->get_gl_context;
  my $gldrawable = $widget->get_gl_drawable;

  # brass
  my @ambient  = ( 0.329412, 0.223529, 0.027451, 1.0 );
  my @diffuse  = ( 0.780392, 0.568627, 0.113725, 1.0 );
  my @specular = ( 0.992157, 0.941176, 0.807843, 1.0 );
  my $shininess   = 0.21794872 * 128.0;

  ### OpenGL BEGIN ###
  return 0 unless $gldrawable->gl_begin ($glcontext);

  glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  glLoadIdentity;
  glTranslatef (0.0, 0.0, -10.0);

  glPushMatrix;
    glTranslatef (0.0, $pos_y, 0.0);
    glRotatef ($angle, 0.0, 1.0, 0.0);
    glMaterialfv_p (GL_FRONT, GL_AMBIENT, @ambient);
    glMaterialfv_p (GL_FRONT, GL_DIFFUSE, @diffuse);
    glMaterialfv_p (GL_FRONT, GL_SPECULAR, @specular);
    glMaterialf (GL_FRONT, GL_SHININESS, $shininess);
    Gtk2::Gdk::GLExt::Shapes->draw_torus (1, 0.3, 0.6, 30, 30);
  glPopMatrix;

  if ($gldrawable->is_double_buffered)
    {
      $gldrawable->swap_buffers;
    }
  else
    {
      glFlush;
    }

  $gldrawable->gl_end;
  ### OpenGL END ###

  return 1;
}

sub timeout {
  my ($widget) = @_;

  my $t;

  $angle += 3.0;
  $angle -= 360.0 if $angle >= 360.0;

  $t = $angle * G_PI / 180.0;
  $t = 2.0 * G_PI - $t if $t > G_PI;

  $pos_y = 2.0 * (sin ($t) + 0.4 * sin (3.0*$t)) - 1.0;

  $widget->queue_draw;

  return 1;
}

my $timeout_id;

sub timeout_add {
  my ($widget) = @_;
  return if defined $timeout_id;
  $timeout_id = Glib::Timeout->add (TIMEOUT_INTERVAL, \&timeout, $widget);
}

sub timeout_remove {
  if (defined $timeout_id) {
    Glib::Source->remove ($timeout_id);
    $timeout_id = undef;
  }
}

sub unrealize {
  my ($widget, $data) = @_;

  timeout_remove;
}

sub map_event {
  my ($widget, $event, $data) = @_;

  timeout_add ($widget) if $animate;

  return 1;
}

sub unmap_event {
  my ($widget, $event, $data) = @_;

  timeout_remove;

  return 1;
}

sub visibility_notify_event {
  my ($widget, $event, $data) = @_;

  if ($animate)
    {
      if (grep { $_ eq 'fully_obscured' } $event->state)
	{
	  timeout_remove;
	}
      else
	{
	  timeout_add ($widget);
	}
    }

  return 1;
}

sub toggle_animation {
  my ($widget) = @_;

  $animate = !$animate;

  if ($animate)
    {
      timeout_add ($widget);
    }
  else
    {
      timeout_remove;
      $widget->queue_draw;
    }
}

sub create_gl_toggle_button {
  my ($glconfig) = @_;

  my $vbox;
  my $drawing_area;
  my $label;
  my $button;

  #
  # VBox.
  #

  $vbox = Gtk2::VBox->new (0, 0);
  $vbox->set_border_width (10);

  #
  # Drawing area for drawing OpenGL scene.
  #

  $drawing_area = Gtk2::DrawingArea->new;
  $drawing_area->set_size_request (200, 200);

  # Set OpenGL-capability to the widget.
  $drawing_area->set_gl_capability ($glconfig, undef, 1, 'rgba_type');

  $drawing_area->signal_connect_after (realize => \&realize);
  $drawing_area->signal_connect (configure_event => \&configure_event);
  $drawing_area->signal_connect (expose_event => \&expose_event);
  $drawing_area->signal_connect (unrealize => \&unrealize);

  $drawing_area->signal_connect (map_event => \&map_event);
  $drawing_area->signal_connect (unmap_event => \&unmap_event);
  $drawing_area->signal_connect (
    visibility_notify_event => \&visibility_notify_event
  );

  $vbox->pack_start ($drawing_area, 1, 1, 0);
  $drawing_area->show;

  #
  # Label.
  #

  $label = Gtk2::Label->new ('Toggle Animation');
  $vbox->pack_start ($label, 0, 0, 10);
  $label->show;

  #
  # Toggle button.
  #

  $button = Gtk2::ToggleButton->new;

  $button->signal_connect (toggled => \&toggle_animation, $drawing_area);

  # Add VBox.
  $vbox->show;
  $button->add ($vbox);

  return $button;
}

sub main {

  my $glconfig;
  my $window;
  my $button;

  #
  # Init GTK.
  #

  # gtk_init (&argc, &argv);

  #
  # Init GtkGLExt.
  #

  Gtk2::GLExt->init;

  #
  # Configure OpenGL-capable visual.
  #

  # Try double-buffered visual
  $glconfig = Gtk2::Gdk::GLExt::Config->new_by_mode ([qw/rgb depth double/]);
  unless ($glconfig)
    {
      print STDERR ("*** Cannot find the double-buffered visual.\n");
      print STDERR ("*** Trying single-buffered visual.\n");

      # Try single-buffered visual
      $glconfig = Gtk2::Gdk::GLExt::Config->new_by_mode ([qw/rgb depth/]);
      unless ($glconfig)
        {
          print STDERR ("*** No appropriate OpenGL-capable visual found.\n");
          exit (1);
        }
    }

  #
  # Top-level window.
  #

  $window = Gtk2::Window->new ('toplevel');
  $window->set_title ('button');

  # Perform the resizes immediately on WIN32
  $window->set_resize_mode ('immediate') if( $^O eq 'MSWin32' );
  # Get automatically redrawn if any of their children changed allocation.
  $window->set_reallocate_redraws (1);
  # Set border width.
  $window->set_border_width (10);

  $window->signal_connect (delete_event => sub {Gtk2->main_quit; 1});

  #
  # Toggle button which contains an OpenGL scene.
  #

  $button = create_gl_toggle_button ($glconfig);
  $button->show;
  $window->add ($button);

  #
  # Show window.
  #

  $window->show;

  #
  # Main loop.
  #

  Gtk2->main;

  return 0;
}

&main;
