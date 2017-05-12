
# Games-Console-OpenGL - a 2D quake-style console (rendered in OpenGL)

package Games::Console::OpenGL;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Games::Console;
use vars qw/@ISA $VERSION/;
@ISA = qw/Games::Console/;

use SDL::OpenGL;

$VERSION = '0.01';

sub _render
  {
  # prepare the output, render the background and the text
  my ($self,$x,$y,$w,$h,$time) = @_;

  # select our background texture
  # glBindTexture( GL_TEXTURE_2D, $self->{texture} );
  glDisable( GL_TEXTURE_2D );

  # Disable/Enable flags, unless they are already in the right state
  glDisable( GL_DEPTH_TEST );
  glDepthMask(GL_FALSE);        # disable writing to depth buffer

  glEnable( GL_BLEND );
  # select type of blending
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

  # Select The Projection Matrix
  glMatrixMode( GL_PROJECTION );
  # Store The Projection Matrix
  glPushMatrix();
  # Reset The Projection Matrix
  glLoadIdentity();

  # Set Up An Ortho Screen
  #        left, right,       bottom, top,        near, far
  glOrtho( 0, $self->{screen_width}, 0, $self->{screen_height}, -1, 1 );

  # Select The Modelview Matrix
  glMatrixMode( GL_MODELVIEW );
  # Store the Modelview Matrix
  glPushMatrix();
  # Reset The Modelview Matrix
  glLoadIdentity();

  ############################################################################
  # draw background

  glColor (@{$self->{background_color}}, $self->{background_alpha});
  glBegin( GL_QUADS );
      glVertex( $x, $y-$h );
      glVertex( $x+$w, $y-$h );
      glVertex( $x+$w, $y );
      glVertex( $x, $y ); 
  glEnd;

  # draw messages
  my $font = $self->{font};
  $font->pre_output();

  my $line_height = $self->{font}->char_height() + $self->{spacing_y};

  my $output_y = ($y - $h + $self->{border_y});
  
  $font->color( $self->{text_color} );
  $font->alpha( $self->{text_alpha} );
  if ($output_y > -$line_height)
    {
    # do we need to draw the cursor? (50% of the time draw it, 50% not)
    my $cursor = '';
    if ($time - $self->{last_cursor} > $self->{cursor_time})
      {
      $cursor = $self->{cursor};
      }
    if ($time - $self->{last_cursor} > 2 * $self->{cursor_time})
      {
      # This isn't necc. correct, but nobody will notice...
      $self->{last_cursor} = $time;
      }
    $font->output ($x + $self->{border_x}, $output_y, 
      $self->{prompt} . $self->{current_input} . $cursor); 
    $output_y += $line_height;
    }
  foreach my $msg (reverse @{$self->{messages}})
    {
    last if $output_y < -$line_height;
    # draw the messages from the bottom to the top
    $font->output ($x + $self->{border_x}, $output_y, $msg->[0] ); 
    $output_y += $line_height;
    }

  $font->post_output();

  ############################################################################

  # Select The Projection Matrix
  glMatrixMode( GL_PROJECTION );
  # Restore The Old Projection Matrix
  glPopMatrix();

  # Select the Modelview Matrix
  glMatrixMode( GL_MODELVIEW );
  # Restore the Old Projection Matrix
  glPopMatrix();

  }

1;

__END__

=pod

=head1 NAME

Games::Console::OpenGL - provide a 2D quake style in-game console via OpenGL

=head1 SYNOPSIS

	use Games::Console::OpenGL;

	my $console = Games::Console::OpenGL->new(
	  font => Games::OpenGL::Font::2D->new( file => 'font.bmp' ),
	  background_color => [ 1,1,0],
	  background_alpha => 0.4,
	  text_color => [ 1,1,1 ],
	  text_alpha => 1,
          speed => 50,		# in percent per second
	  height => 50,		# fully opened, in percent of screen
	  width => 100,		# fully opened, in percent of screen
	);

	$console->toggle($current_time);
	$console->message('Hello there!', $loglevel);


=head1 EXPORTS

Exports nothing on default. 

=head1 DESCRIPTION

This package provides you with a quake-style console for your games. The
console can parse input, log to a logfile, and gather messages.

This package renders the console via OpenGL. Please see L<Games::Console>
for a full documentation.

=head1 KNOWN BUGS

None yet.

=head1 AUTHORS

(c) 2003 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::3D>, L<SDL:App::FPS>, and L<SDL::OpenGL>.

=cut

