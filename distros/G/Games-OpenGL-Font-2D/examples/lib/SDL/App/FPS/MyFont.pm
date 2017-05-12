
# example of SDL::App::FPS demonstrating usage of OpenGL 2D fonts.

package SDL::App::FPS::MyFont;

# (C) 2003, 2006 by Tels <http://bloodgate.com/>

use strict;

use SDL::OpenGL;
use SDL::OpenGL::Cube;
use SDL::App::FPS qw/
  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_RIGHT
  /;
use SDL;

use base qw/SDL::App::FPS/;

use Games::OpenGL::Font::2D qw/FONT_ALIGN_RIGHT FONT_ALIGN_BOTTOM/;

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

  foreach my $f (qw/font font_ver font_ver_zoom font_right font_bottom/)
    {
    $self->{$f}->screen_width( $self->width() );
    $self->{$f}->screen_height( $self->height() );
    }
  }

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  # using pause() would be a bit more efficient, though 
  return if $self->time_is_frozen();
       
  $self->_gl_draw_cube();

  $self->{font}->pre_output();
 
  $self->{font}->output ( 5, $self->height() - 20, int($current_fps) . " FPS" );

  $self->{font}->output ( ($current_time / 50) % 400 + 50, 
    sin ( ($current_time / 400)) * 50 + 180, 
     'Hello SDL::App::FPS!', [1,0.2,0.2] );

  if ($self->{benchmark})
    {
    for (1..128)
      {
      my $x = rand($self->width()); 
      my $y = rand($self->height());
      $self->{font}->output ( $x, $y, 'Benchmark!', 
         [ rand(), rand(), rand() ], 1);
      }
    }
  $self->{font}->post_output();

  $self->{font_ver}->pre_output();
  $self->{font_ver}->output ( 150,
     ($current_time / 250) % 400 + $self->height() - 200,
    'Hello SDL_Perl!', [ 1,1,0] );
  $self->{font_ver}->post_output();

  $self->{font_ver_zoom}->pre_output();
  $self->{font_ver_zoom}->output ( ($current_time / 100) % 300 + 100,
     ($current_time / 150) % 200 + $self->height() - 100,
    'Hello OpenGL!', [ 0,0.7,1] );
  $self->{font_ver_zoom}->post_output();
  
  # some aligned text
  $self->{font_right}->pre_output();
  $self->{font_right}->output ( $self->width() - 5, 
     ($current_time / 150) % 200 + 100,
   'Right aligned text.');
  $self->{font_right}->post_output();
  
  $self->{font_bottom}->pre_output();
  $self->{font_bottom}->output ( 
     ($current_time / 150) % 200 + 100,
     0, 'Bottom aligned text.');
  $self->{font_bottom}->post_output();

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
  $self->{font_ver} = $self->{font}->copy();
  $self->{font_ver}->spacing(0,-21);	# vertical output
  $self->{font_ver_zoom} = $self->{font}->copy();
  $self->{font_ver_zoom}->spacing(0,-21);	# vertical output
  $self->{font_ver_zoom}->zoom(2,2);		# zoomed
  $self->{font_right} = $self->{font}->copy();
  $self->{font_right}->align_x(FONT_ALIGN_RIGHT);
  $self->{font_bottom} = $self->{font}->copy();
  $self->{font_bottom}->spacing(0,-21);		# vertical output
  $self->{font_bottom}->align_y(FONT_ALIGN_BOTTOM);
  print "done.\n";
  
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

  $self->{benchmark} = 0;
  $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_LEFT,
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('2',1500);           # ramp up
     });
  $self->add_event_handler (SDL_KEYDOWN, SDLK_b,
   sub {
     my $self = shift;
     $self->{benchmark} = 1 - $self->{benchmark};
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

