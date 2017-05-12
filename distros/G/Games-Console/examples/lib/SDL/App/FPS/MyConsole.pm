
# example of SDL::App::FPS demonstrating usage of OpenGL 2D fonts.

package SDL::App::FPS::MyFont;

# (C) 2003 by Tels <http://bloodgate.com/>

use strict;

use SDL::OpenGL;
use SDL::OpenGL::Cube;
use SDL::App::FPS qw/
  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_RIGHT
  /;
use SDL::Event;

use vars qw/@ISA/;
@ISA = qw/SDL::App::FPS/;

use Games::OpenGL::Font::2D 
  qw/FONT_ALIGN_RIGHT FONT_ALIGN_LEFT FONT_ALIGN_BOTTOM/;
use Games::Console::OpenGL;

##############################################################################

sub _gl_draw_cube
  {
  my $self = shift;

  glClear( GL_DEPTH_BUFFER_BIT() | GL_COLOR_BUFFER_BIT());

  glLoadIdentity();

  glTranslate(0,0,-6.0);

  # compute the current angle based on elapsed time

  my $angle = ($self->current_time() / 5) % 360;
  my $other = ($self->current_time() / 7) % 360;

  glRotate($angle,1,1,0);
  glRotate($other,0,1,1);

  glColor(1,1,1);
  glDisable( GL_TEXTURE_2D );
  $self->{cube}->draw();
  }

sub _gl_init_view
  {
  my $self = shift;

  glViewport(0,0,$self->width(),$self->height());

  glMatrixMode(GL_PROJECTION());
  glLoadIdentity();

  if ( @_ )
    {
    glPerspective(45.0,4/3,0.1,100.0);
    }
  else
    {
    glFrustum(-0.1,0.1,-0.075,0.075,0.3,100.0);
    }

  glMatrixMode(GL_MODELVIEW());
  glLoadIdentity();
  
  glEnable(GL_CULL_FACE);
  glFrontFace(GL_CCW);
  glCullFace(GL_BACK);

  # register the screen size with the various objects that render to it in
  # Ortho projection

  foreach my $f (qw/font/)
    {
    $self->{$f}->screen_width( $self->width() );
    $self->{$f}->screen_height( $self->height() );
    }
  $self->{console}->screen_width( $self->width() );
  $self->{console}->screen_height( $self->height() );
  
  $self->{console}->message(
    scalar localtime() . ' OpenGL init successfull.',1);
  $self->{console}->message(
    scalar localtime() . ' Video resolution ' .
     $self->width() . 'x' . $self->height() . ' at ' . $self->depth() . 
     ' bits, ' . ($self->in_fullscreen() ? 'fullscreen' : 'windowd'),
    1);
  }

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  # using pause() would be a bit more efficient, though 
  return if $self->time_is_frozen();
       
  $self->_gl_draw_cube();

  $self->{console}->render($current_time);

  $self->{font}->pre_output();
  $self->{font}->output ( $self->width() - 5, 0, int($current_fps) . " FPS" ); 
  $self->{font}->post_output();

  SDL::GLSwapBuffers();		# without this, you won't see anything!
  }

sub resize_handler
  {
  my $self = shift;

  $self->_gl_init_view();
  }

sub post_init_handler
  {
  my $self = shift;

  print "Constructing font...";
  $self->{font} = Games::OpenGL::Font::2D->new( 
     file => '../data/courier.bmp',
     chars => 256-32,
     chars_per_line => 16,
     char_width => 11,
     char_height => 21,
     );
  $self->{font}->align_x (FONT_ALIGN_RIGHT);
  # don't re-use the font object for the console!
  $self->{console_font} = $self->{font}->copy();
  $self->{console_font}->align_x(FONT_ALIGN_LEFT);
  $self->{console_font}->zoom(0.8,0.8);
  print "done.\n";
 
  $self->{console} = Games::Console::OpenGL->new(
    font => $self->{console_font},
   );

  $self->{console}->message(
    scalar localtime() . ' SDL::App::FPS Console demo started', 1);
  $self->{console}->message('Hello Perl!',1); 

  $self->_gl_init_view();

  $self->{cube} = SDL::OpenGL::Cube->new();

  my @colors =  (
        1.0,1.0,0.0,    1.0,0.0,0.0,    0.0,1.0,0.0, 0.0,0.0,1.0,       #back
        0.4,0.4,0.4,    0.3,0.3,0.3,    0.2,0.2,0.2, 0.1,0.1,0.1 );     #front

  $self->{cube}->color(@colors);

  # set up some event handlers
  $self->watch_event ( 
    quit => SDLK_q, fullscreen => SDLK_f, freeze => SDLK_SPACE,
   );

  $self->add_event_handler (SDL_KEYDOWN, SDLK_c,
   sub {
     my $self = shift;
     $self->{console}->toggle($self->current_time());
     });
  
  $self->add_event_handler (SDL_KEYDOWN, SDLK_m,
   sub {
     my $self = shift;
     $self->{console}->message( scalar localtime() . ' Some message',1);
     });

  $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_LEFT,
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('2',1500);           # ramp up
     });
  $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_RIGHT,
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('0.3',1500);         # ramp down
     });
  $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_MIDDLE,
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('1',1500);           # ramp to normal
     });
  }

1;

__END__

