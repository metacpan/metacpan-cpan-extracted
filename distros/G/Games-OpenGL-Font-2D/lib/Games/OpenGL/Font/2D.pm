# Games-OpenGL-Font-2D - load/render 2D fonts via OpenGL

package Games::OpenGL::Font::2D;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Exporter;
use SDL::OpenGL;
use SDL::Surface;
use vars qw/@ISA $VERSION @EXPORT_OK/;
@ISA = qw/Exporter/;

@EXPORT_OK = qw/
	FONT_ALIGN_LEFT FONT_ALIGN_RIGHT FONT_ALIGN_CENTER
	FONT_ALIGN_TOP FONT_ALIGN_BOTTOM
	/;

$VERSION = '0.07';

##############################################################################
# constants

use constant FONT_ALIGN_LEFT => -1;
use constant FONT_ALIGN_RIGHT => 1;
use constant FONT_ALIGN_CENTER => 0;

use constant FONT_ALIGN_TOP => -1;
use constant FONT_ALIGN_BOTTOM => 1;

##############################################################################
# methods

sub new
  {
  # create a new instance of a font
  my $class = shift;

  my $self = { };
  bless $self, $class;
  
  my $args = $_[0];
  $args = { @_ } unless ref $args eq 'HASH';

  $self->{file} = $args->{file} || '';
  $self->{color} = $args->{color} || [ 1,1,1 ];
  $self->{alpha} = $args->{alpha} || 1;
  $self->{char_width} = int(abs($args->{char_width} || 16));
  $self->{char_height} = int(abs($args->{char_height} || 16));
  $self->{spacing_x} = int($args->{spacing_x} || $self->{char_width});
  $self->{spacing_y} = int($args->{spacing_y} || 0);
  $self->{transparent} = 1;
  $self->{width} = 640;
  $self->{height} = 480;
  $self->{zoom_x} = abs($args->{zoom_x} || 1);
  $self->{zoom_y} = abs($args->{zoom_y} || 1);
  $self->{chars} = int(abs($args->{chars} || (256-32)));
  $self->{chars_per_line} = int(abs($args->{chars_per_line} || 32));
  $self->{align_x} = $args->{align_x};
  $self->{align_y} = $args->{align_y};
  $self->{align_y} = -1 unless defined $self->{align_y};
  $self->{align_x} = -1 unless defined $self->{align_x};
  $self->{align_x} = int($self->{align_x});
  $self->{align_y} = int($self->{align_x});
  $self->{border_x} = int(abs($args->{border_x} || 0));
  $self->{border_y} = int(abs($args->{border_y} || 0));
  
  $self->_read_font($self->{file});
  
  $self->{pre_output} = 0;
  
  # Create the display lists
  $self->{base} = glGenLists( $self->{chars} );

  $self->_build_font();
  $self;
  }

sub _read_font
  {
  my $self = shift;

  # load the file as SDL::Surface into memory
  my $font = SDL::Surface->new( -name => $self->{file} );

  # create one texture and bind it to our object's member 'texture'
  $self->{texture} = glGenTextures(1)->[0];
  glBindTexture( GL_TEXTURE_2D, $self->{texture} );

  # Select nearest filtering
  glTexParameter( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
  glTexParameter( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

  # generate the OpenGL texture
  glTexImage2D(
    GL_TEXTURE_2D, 0, 3, $font->width(), $font->height(), 0, GL_BGR,
    GL_UNSIGNED_BYTE, $font->pixels() );

  $self->{texture_width} = $font->width();
  $self->{texture_height} = $font->height();

  # $font will go out of scope and thus freed at the end of this sub
  }

sub _build_font
  {
  my $self = shift;

  # select our font texture
  glBindTexture( GL_TEXTURE_2D, $self->{texture} );

  my $cw = $self->{char_width};
  my $ch = $self->{char_height};
  my $w = int($cw * $self->{zoom_x});
  my $h = int($ch * $self->{zoom_y});
  my $bx = $self->{border_x};
  my $by = $self->{border_y};
  # calculate w/h of a char in 0..1 space
  my $cwi = ($cw+$bx)/$self->{texture_width};
  my $chi = ($ch+$by)/$self->{texture_height};
  $cw = $cw/$self->{texture_width};
  $ch = $ch/$self->{texture_height};
  # print "$self->{file}: $cw x $ch ($w x $h => ",$w+$bx," x ",$h+$by,") $self->{base} ($self->{texture_width} x $self->{texture_height})\n";
  my $cx = 0; my $cy = 0;
  my $c = 0;
  # loop through all characters
  for my $loop (1 .. $self->{chars})
    {
    # start building a list
    glNewList( $self->{base} + $loop - 1, GL_COMPILE ); 
    # Use A Quad For Each Character
    glBegin( GL_QUADS );

      # Bottom Left 
      glTexCoord( $cx, $cy + $ch);	# was: 0.0625
      glVertex( 0, 0 );

      # Bottom Right
      glTexCoord( $cx + $cw, $cy + $ch);
      glVertex( $w, 0 );

      # Top Right
      glTexCoord( $cx + $cw, $cy);
      glVertex( $w, $h );

      # Top Left 
      glTexCoord( $cx , $cy);
      glVertex( 0, $h );

    glEnd();

    # move to next character
    glTranslate( $self->{spacing_x} * $self->{zoom_x}, 
                 $self->{spacing_y} * $self->{zoom_y}, 0 );
    glEndList();
    
    # X and Y position of next char
    $cx += $cwi;
    if (++$c >= $self->{chars_per_line})
      {
      $c = 0; $cx = 0; $cy += $chi;
      }


    }
  }

sub pre_output
  {
  my $self = shift;

  warn ("pre_output() called twice") if $self->{pre_output} != 0;
  $self->{pre_output} = 1;

  # Select our texture
  glBindTexture( GL_TEXTURE_2D, $self->{texture} );

  $self->{gl_flags} = [ 
    glIsEnabled(GL_DEPTH_TEST),
    glIsEnabled(GL_TEXTURE_2D),
    glIsEnabled(GL_CULL_FACE),
    ];
  # Disable/Enable flags
  glDisable( GL_DEPTH_TEST );
  glEnable( GL_TEXTURE_2D );
  glDisable( GL_CULL_FACE );
  glDepthMask(GL_FALSE);	# disable writing to depth buffer
  
  glEnable( GL_BLEND );
  # Select The Type Of Blending
  if ($self->{transparent})
    {
    glBlendFunc(GL_SRC_ALPHA,GL_ONE);
    }
  else
    {
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    }

  # Select The Projection Matrix
  glMatrixMode( GL_PROJECTION );
  # Store The Projection Matrix
  glPushMatrix();
  # Reset The Projection Matrix
  glLoadIdentity();

  # Set Up An Ortho Screen 
  #        left, right,       bottom, top,        near, far
  glOrtho( 0, $self->{width}, 0, $self->{height}, -1, 1 );
  
  # Select The Modelview Matrix
  glMatrixMode( GL_MODELVIEW );
  # Store the Modelview Matrix
  glPushMatrix();
  # Reset The Modelview Matrix
  glLoadIdentity();
  }

sub output
  {
  # Output the given string at the coordinates
  my ($self,$x,$y,$string,$color,$alpha) = @_;

  return if $string eq '';

  # Reset The Modelview Matrix
  glLoadIdentity();

  if ($self->{align_x} != FONT_ALIGN_LEFT)
    {
    # center or right aligned
    my $tw = abs((length($string)-1) * $self->{spacing_x} * $self->{zoom_x});
    # vertical text 
    $tw += $self->{char_width} * $self->{zoom_x};
    if ($self->{align_x} == FONT_ALIGN_RIGHT)
      {
      $x = $x - $tw;
      }
    else
      {
      $x = $x - $tw / 2;
      }
    }
  if ($self->{align_y} != FONT_ALIGN_TOP)
    {
    my $th = abs((length($string)) * $self->{spacing_y} * $self->{zoom_y});
    $th -= $self->{char_height} * $self->{zoom_y};
    if ($self->{align_y} == FONT_ALIGN_BOTTOM)
      {
      $y = $y + $th;
      }
    else
      {
      $y = $y + $th / 2;
      }
    }

  # translate to the top-left position of the text (after alignment)
  glTranslate( $x, $y, 0 );

  # set color and alpha value
  $color = $self->{color} unless defined $color;
  $alpha = $self->{alpha} unless defined $alpha;
  if (defined $color)
    {
    # if not, caller wanted to set color by herself
    if (defined $alpha)
      {
      glColor (@$color,$alpha);
      }
    else
      {
      glColor (@$color,1);
      }
    }

  # Choose The Font Set (0 or 1) (-32 because our lists start at 0, and space
  # has an ASCII value of 32 and is the first existing character)
  glListBase( $self->{base} - 32 );

  # render the string to the screen
  glCallListsString( $string );

  }

sub post_output
  {
  my $self = shift;

  warn ("post_output() called before pre_output()")
    if $self->{pre_output} == 0;
  $self->{pre_output} = 0;

  # Reset the OpenGL stuff

  # Select The Projection Matrix
  glMatrixMode( GL_PROJECTION );
  # Restore The Old Projection Matrix 
  glPopMatrix();

  # Select the Modelview Matrix 
  glMatrixMode( GL_MODELVIEW );
  # Restore the Old Projection Matrix
  glPopMatrix();

  my $flags = $self->{gl_flags};
  glEnable(GL_DEPTH_TEST)  if $flags->[0];
  glEnable(GL_TEXTURE_2D)  if $flags->[1];
  glEnable(GL_CULL_FACE)   if $flags->[2];
  glDepthMask(GL_TRUE);		# enable writing to depth buffer
  
  # Caller must re-enable or re-disable other flags if she wishes
  }

sub screen_width
  {
  my $self = shift;

  $self->{width} = shift if @_ > 0;
  $self->{width};
  }

sub screen_height
  {
  my $self = shift;

  $self->{height} = shift if @_ > 0;
  $self->{height};
  }

sub color
  {
  my $self = shift;

  if (@_ > 0)
    {
    if (ref($_[0]) eq 'ARRAY')
      {
      $self->{color} = shift;
      }
    else
      {
      $self->{color} = [ $_[0], $_[1], $_[2] ];
      }
    }
  $self->{color};
  }

sub transparent
  {
  my $self = shift;

  $self->{transparent} = shift if @_ > 0;
  $self->{transparent};
  }

sub alpha
  {
  my $self = shift;

  $self->{alpha} = shift if @_ > 0;
  $self->{alpha};
  }

sub spacing_x
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{spacing_x} = shift;
    $self->_build_font();
    }
  $self->{spacing_x};
  }

sub spacing_y
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{spacing_y} = shift;
    $self->_build_font();
    }
  $self->{spacing_y};
  }

sub spacing
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{spacing_x} = shift;
    $self->{spacing_y} = shift;
    $self->_build_font();
    }
  ($self->{spacing_x}, $self->{spacing_y});
  }

sub border_x
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{border_x} = iint(abs(shift));
    $self->_build_font();
    }
  $self->{border_x};
  }

sub border_y
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{border_y} = iint(abs(shift));
    $self->_build_font();
    }
  $self->{border_y};
  }

sub zoom
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{zoom_x} = shift;
    $self->{zoom_y} = shift;
    $self->_build_font();
    }
  ($self->{zoom_x}, $self->{zoom_y});
  }

sub copy
  {
  my $self = shift;

  my $class = ref($self);
  my $new = {};
  foreach my $k (keys %$self)
    {
    $new->{$k} = $self->{$k};
    }
  $new->{base} = glGenLists ( $self->{chars} );	# get the new font some lists
  bless $new, $class;
  $new->_build_font();
  $new;
  }

sub align_x
  {
  my $self = shift;

  $self->{align_x} = shift if @_ > 0;
  $self->{align_x};
  }

sub align_y
  {
  my $self = shift;

  $self->{align_y} = shift if @_ > 0;
  $self->{align_y};
  }

sub align
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{align_x} = shift;
    $self->{align_y} = shift;
    }
  ($self->{align_x}, $self->{align_y});
  }

sub char_height
  {
  my $self = shift;

  $self->{char_height} * $self->{zoom_y};
  }

sub char_width
  {
  my $self = shift;

  $self->{char_width} * $self->{zoom_x};
  }

sub DESTROY
  {
  my $self = shift;

  # free the texture lists
  glDeleteLists( $self->{base}, $self->{chars} ) if defined $self->{base};
  }

1;

__END__

=pod

=head1 NAME

Games::OpenGL::Font::2D - load/render 2D colored bitmap fonts via OpenGL

=head1 SYNOPSIS

	use Games::OpenGL::Font::2D;

	my $font = Games::OpenGL::Font::2D->new( 
          file => 'font.bmp' );

	use SDL::App::FPS;

	my $app = SDL::App::FPS->new( ... );

	# don't forget to change these on resize events!
	$font->screen_width( $app->width() );
	$font->screen_height( $app->width() );

	$font->pre_output();		# setup rendering for font
	
	$font->color( [ 0,1,0] );	# yellow as array ref
	$font->color( 1,0,0 );		# or red
	$font->alpha( 0.8 );		# nearly opaque

	# half-transparent, red
	$font->output (100,100, 'Hello OpenGL!', [ 1,0,0], 0.5 );
	# using the $font's color and alpha
	$font->output (100,200, 'Hello OpenGL!' );
	
	$font->transparent( 1 );	# render font background transparent
	
	$font->spacing_y( 16 );		# render vertical (costly rebuild!)
	$font->spacing_x( 0 );		# (costly rebuild!)
	$font->output (100,200, 'Hello OpenGL!' );

	$font->post_output();		# if wanted, you can reset OpenGL

=head1 EXPORTS

Exports nothing on default. Can export on demand the following:

	FONT_ALIGN_LEFT
	FONT_ALIGN_RIGHT
	FONT_ALIGN_CENTER
	FONT_ALIGN_TOP
	FONT_ALIGN_BOTTOM

=head1 DESCRIPTION

This package lets you load and render colored bitmap fonts via OpenGL.

=head1 METHODS

=over 2

=item new()

	my $font = OpenGL::Font::2D->new( $args );

Load a font into memory and return an object reference. C<$args> is a hash
ref containing the following keys:

	file		filename of font bitmap
	transparent	if true, render font background transparent (e.g.
			don't render the background)
	color		color of output text as array ref [r,g,b]
	alpha		blend font over background for semitransparent
	char_width	Width of each char on the texture
	char_height	Width of each char on the texture
  	chars		Number of characters on font-texture
	spacing_x	Spacing in X direction after each char
	spacing_y	Spacing in Y direction after each char
	align_x		Align the font output in X direction
			Possible: FONT_ALIGN_LEFT, FONT_ALIGN_RIGHT and
			FONT_ALIGN_CENTER
	align_y		Align the font output in Y direction
			Possible: FONT_ALIGN_TOP, FONT_ALIGN_BOTTOM and
			FONT_ALIGN_CENTER
	border_x	Space between each char in the texture in X dir
	border_y	Likewise border_x, but in Y dir

Example:

	my $font = OpenGL::Font::2D->new( file => 'data/courier.txt',
		char_width => 11, char_height => 21, 
		zoom_x => 2, zoom_y => 1,
		spacing_x => 21, spacing_y => 0,
	);

=item output()

	$font->output ($x,$y, $string, $color, $alpha);

Output the string C<$string> at the coordinates $x and $y. 0,0 is at the
lower left corner of the screen.

C<$color> and C<$alpha> are optional and if omitted or given as undef, will
be taken from the font's internal values, which can be given at new() or
modified with the routines below.

=item transparent()

	$model->frames();

Get/set the font's transparent flag. Setting it to true renders the font
background as transparent.

=item color()

        $rgb = $font->color();		# [$r,$g, $b ]
        $font->color(1,0.1,0.8);	# set RGB
        $font->color([1,0.1,0.8]);	# same, as array ref
        $font->color(undef);		# no color

Sets the color, that will be set to render the font. No color means the caller
can set the color before calling L<output()>.

=item alpha()

        $a = $font->alpha();		# $a
        $font->color(0.8);		# set A
        $font->alpha(undef);		# set's it to 1.0 (seems an OpenGL
					# specific set because
					# glColor($r,$g,$b) also sets $a == 1

Sets the alpha value of the rendered output.

=item spacing_x()

	$x = $font->spacing_x();
	$font->spacing_x( $new_width );

Get/set the width of each character. Default is 10. This is costly, since it
needs to rebuild the font. See also L<spacing_y()> and L<spacing()>.

=item spacing_y()

	$x = $font->spacing_y();
	$font->spacing_y( $new_height );

Get/set the width of each character. Default is 0. This is costly, since it
needs to rebuild the font. See also L<spacing_x()> and L<spacing()>.

=item spacing()

	($x,$y) = $font->spacing();
	$font->spacing( $new_width, $new_height );

Get/set the width and height of each character. Default is 10 and 0. This is
costly, since it needs to rebuild the font. If you need to render vertical
texts, you can use this:

	$font->spacing(0,16);

However, for mixing vertical and horizontal text, better create two font's
objects by cloning an existing:
	
	$font_hor = OpenGL::Font::2D->new( ... );
	$font_ver = $font_hor->copy();
	$font_ver->spacing(0,16);

The two font objects will thus share the texture, and you don't need to
rebuild the font by setting the spacing for each text you want to render.

See also L<spacing_x()> and L<spacing_y()>.

=item zoom()

	($x,$y) = $font->zoom();
	$font->zoom( $new_width, $new_height );

Get/set the zoom factor for each character. Default is 1 and 1. This is
costly, since it needs to rebuild the font. See L<spacing()> on how to
avoid the font-rebuilding for each text output.

=item pre_output()

	$font->pre_output();

Sets up OpenGL so that the font can be rendered on the screen. 

=item post_output()

	$font->post_output();

Resets some OpenGL stuff after rendering. If you reset OpenGL for the next
frame anyway, or use a different font's pre_ouput() afterwards, you can skip
this.

Please remember to enable/disable any flags that you might want. 

Also note, post_output() enables writes to the depth buffer, regardless of
whether they were enabled or not before pre_output() was called.

=item border_x()

	$bx = $font->border_x();
	$font->border_x( 1 );

Get/set the border on the right side of each char on the texture map. E.g.
if each char is 31 pixel wide, but occupies 32 pixel, border_x should be set
to 1. Costly, since it rebuilds the font.

=item border_y()

	$by = $font->border_y();
	$font->border_y( 1 );

Get/set the border on the lower side of each char on the texture map. E.g.
if each char is 31 pixel heigh, but occupies 32 pixel, border_y should be set
to 1. Costly, since it rebuilds the font.

=item align_x()

	$x = $font->align_x();
	$font->align_x( FONT_ALIGN_RIGHT );

Get/set the alignment of the output in X direction.

=item align_y()

	$x = $font->align_y();
	$font->align_y( FONT_ALIGN_TOP );

Get/set the alignment of the output in Y direction.

=item align()

	($x,$y) = $font->align();
	$font->align( FONT_ALIGN_RIGHT, FONT_ALIGN_TOP );

Get/set the alignment of the output in X and Y direction.

=item char_width()

	$w = $font->char_width();

Get the width of one character.

=item char_height()

	$w = $font->char_height();

Get the height of one character.

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHORS

(c) 2003, 2006 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::3D>, L<SDL:App::FPS>, and L<SDL::OpenGL>.

=cut

