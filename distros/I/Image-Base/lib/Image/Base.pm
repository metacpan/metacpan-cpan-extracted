package Image::Base ;    # Documented at the __END__

use 5.004 ;   # 5.004 for __PACKAGE__ special literal
use strict ;

use vars qw( $VERSION ) ;

$VERSION = '1.17' ;

use Carp qw( croak ) ;

# uncomment this to run the ### lines
#use Smart::Comments '###';

# All the supplied methods are expected to be inherited by subclasses; some
# will be adequate, some will need to be overridden and some *must* be
# overridden.

### Private methods 
#
# _get          object
# _set          object

sub _get { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;
   
    $self->{shift()} ;
}


sub _set { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;
    
    my $field = shift ;

    $self->{$field} = shift ;
}


sub DESTROY {
    ; # Save's time
}


### Public methods


sub new   { croak __PACKAGE__ .  "::new() must be overridden" }
sub xy    { croak __PACKAGE__ .   "::xy() must be overridden" }
sub load  { croak __PACKAGE__ . "::load() must be overridden" }
sub save  { croak __PACKAGE__ . "::save() must be overridden" }
sub set   { croak __PACKAGE__ .  "::set() must be overridden" }


sub get { # Object method 
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;
  
    my @result ;

    push @result, $self->_get( shift() ) while @_ ;

    wantarray ? @result : shift @result ;
}


sub new_from_image { # Object method 
    my $self     = shift ; # Must be an image to copy
    my $class    = ref( $self ) || $self ;
    my $newclass = shift ; # Class of target taken from class or object

    croak "new_from_image() cannot read $class" unless $self->can( 'xy' ) ;

    my( $width, $height ) = $self->get( -width, -height ) ;

    # If $newclass was an object reference we inherit its characteristics
    # except for width/height and any arguments we've supplied.
    my $obj = $newclass->new( @_, -width => $width, -height => $height ) ;

    croak "new_from_image() cannot convert to " . ref $obj unless $obj->can( 'xy' ) ;

    for( my $x = 0 ; $x < $width ; $x++ ) {
        for( my $y = 0 ; $y < $height ; $y++ ) {
            $obj->xy( $x, $y, $self->xy( $x, $y ) ) ;
        }
    }

    $obj ;
}


sub line { # Object method
    my( $self, $x0, $y0, $x1, $y1, $colour ) = @_ ;

    # basic Bressenham line drawing

    my $dy = abs ($y1 - $y0);
    my $dx = abs ($x1 - $x0);
    #### $dy
    #### $dx

    if ($dx >= $dy) {
        # shallow slope

        ( $x0, $y0, $x1, $y1 ) = ( $x1, $y1, $x0, $y0 ) if $x0 > $x1 ;

        my $y = $y0 ;
        my $ystep = ($y1 > $y0 ? 1 : -1);
        my $rem = int($dx/2) - $dx;
        for( my $x = $x0 ; $x <= $x1 ; $x++ ) {
            #### $rem
            $self->xy( $x, $y, $colour ) ;
            if (($rem += $dy) >= 0) {
                $rem -= $dx;
                $y += $ystep;
            }
        }
    } else {
        # steep slope

        ( $x0, $y0, $x1, $y1 ) = ( $x1, $y1, $x0, $y0 ) if $y0 > $y1 ;

        my $x = $x0 ;
        my $xstep = ($x1 > $x0 ? 1 : -1);
        my $rem = int($dy/2) - $dy;
        for( my $y = $y0 ; $y <= $y1 ; $y++ ) {
            #### $rem
            $self->xy( $x, $y, $colour ) ;
            if (($rem += $dx) >= 0) {
                $rem -= $dy;
                $x += $xstep;
            }
        }
    }
}


# Midpoint ellipse algorithm from Computer Graphics Principles and Practice.
#
# The points of the ellipse are
#     (x/a)^2 + (y/b)^2 == 1
# or expand out to
#     x^2*b^2 + y^2*a^2 == a^2*b^2
#
# The x,y coordinates are taken relative to the centre $ox,$oy, with radials
# $a and $b half the width $x1-x0 and height $y1-$y0.  If $x1-$x0 is odd,
# then $ox and $a are not integers but have 0.5 parts.  Starting from $x=0.5
# and keeping that 0.5 means the final xy() pixels drawn in
# &$ellipse_point() are integers.  Similarly for y.
#
# Only a few lucky pixels exactly satisfy the ellipse equation above.  For
# the rest there's an error amount expressed as
#
#     E(x,y) = x^2*b^2 + y^2*a^2 - a^2*b^2
#
# The first loop maintains a "discriminator" d1 in $d
#
#     d1 = (x+1)^2*b^2 + (y-1/2)^2*a^2 - a^2*b^2
#
# which is E(x+1,y-1/2), being the error amount for the next x+1 position,
# taken at y-1/2 which is the midpoint between the possible next y or y-1
# pixels.  When d1 > 0 it means that the y-1/2 position is outside the
# ellipse and the y-1 pixel is taken to be the better approximation to the
# ellipse than y.
#
# The first loop does the four octants near the Y axis, ie. the nearly
# horizontal parts.  The second loop does the four octants near the X axis,
# ie. the nearly vertical parts.  For the second loop the discriminator in
# $d is instead at the next y-1 position and between x and x+1,
#
#     d2 = E(x+1/2,y-1) = (x+1/2)^2*b^2 + (y-1)^2*a^2 - a^2*b^2
#
# The difference between d1 and d2 for the changeover is as follows and is
# used to step across to the new position rather than a full recalculation.
# Not much difference in speed, but less code.
#
#     E(x+1/2,y-1) - E(x+1,y-1/2)
#            = -b^2 * (x + 3/4) + a^2 * (3/4 - y)
#
#     since (x+1/2)^2 - (x+1)^2 = -x - 3/4
#           (y-1)^2 - (y-1/2)^2 = -y + 3/4
#
#
# Other Possibilities:
#
# The calculations could be made all-integer by counting $x and $y from 0 at
# the bounding box edges and measuring inwards, rather than outwards from a
# fractional centre.  E(x,y) could have a factor of 2 or 4 put through as
# necessary, the discriminating >0 or <0 staying the same.  The d1 and d2
# steps are at most roughly 2*max(a*b^2,b*a^2), which for a circle means
# 2*r^3.  This fits a 32-bit signed integer for up to about 1000 pixels or
# so, and then of course Perl switches to 53-bit floats automatically, which
# is still an exact integer up to about 160,000 pixels radius.
#
# It'd be possible to draw runs of horizontal pixels with line() instead of
# individual xy() calls.  That might help subclasses doing a block-fill for
# a horizontal line segment.  Except only big or flat ellipses have more
# than a few adjacent horizontal pixels.  Perhaps just the initial topmost
# horizontal, using a sqrt to calculate where it crosses from the top y=b
# down to y=b-1.
#
# The end o the first loop could be pre-calculated (with a sqrt), if that
# seemed better than watching $aa*($y-0.5) vs $bb*($x+1).  The loop change
# is where the tangent slope is steeper than -1.  Drawing a little diagram
# shows that an x+0,y+1 downward step like in the second loop is not needed
# until that point.
#
#      dx/dy = -x*b^2 / y*a^2 = -1             slope
#      y = x*b^2/a^2
#      b^2*x^2 + a^2*(b^4/a^4)*x^2 = a^2*b^2   into the ellipse equation
#      x^2 * (1 + b^2/a^2) = a^2
#      x = a * sqrt (a^2 / (a^2 + b^2))
#        = a^2 / sqrt (a^2 + b^2)
#

sub ellipse { # Object method
    my $self  = shift ;
    #    my $class = ref( $self ) || $self ;

    my( $x0, $y0, $x1, $y1, $colour, $fill ) = @_ ;

    # per the docs, x0,y0 top left, x1,y1 bottom right
    # could relax that fairly easily, if desired ...
    ### assert: $x0 <= $x1
    ### assert: $y0 <= $y1

    my ($a, $b);
    if (($a    = ( $x1 - $x0 ) / 2) <= .5
        || ($b = ( $y1 - $y0 ) / 2) <= .5) {
        # one or two pixels high or wide, treat as rectangle
        $self->rectangle ($x0, $y0, $x1, $y1, $colour );
        return;
    }
    my $aa = $a ** 2 ;
    my $bb = $b ** 2 ;
    my $ox = ($x0 + $x1) / 2;
    my $oy = ($y0 + $y1) / 2;

    my $x  = $a - int($a) ;  # 0 or 0.5
    my $y  = $b ;
    ### initial: "origin $ox,$oy  start xy $x,$y"

    my $ellipse_point =
      ($fill
       ? sub {
           ### ellipse_point fill: "$x,$y"
           $self->line( $ox - $x, $oy + $y,
                        $ox + $x, $oy + $y, $colour ) ;
           $self->line( $ox - $x, $oy - $y,
                        $ox + $x, $oy - $y, $colour ) ;
       }
       : sub {
           ### ellipse_point xys: "$x,$y"
           $self->xy( $ox + $x, $oy + $y, $colour ) ;
           $self->xy( $ox - $x, $oy - $y, $colour ) ;
           $self->xy( $ox + $x, $oy - $y, $colour ) ;
           $self->xy( $ox - $x, $oy + $y, $colour ) ;
       });

    # Initially,
    #     d1 = E(x+1,y-1/2)
    #        = (x+1)^2*b^2 + (y-1/2)^2*a^2 - a^2*b^2
    # which for x=0,y=b is
    #        = b^2 - a^2*b + a^2/4
    # or for x=0.5,y=b
    #        = 9/4*b^2 - ...
    #
    my $d = ($x ? 2.25*$bb : $bb) - ( $aa * $b ) + ( $aa / 4 ) ;

    while( $y >= 1
           && ( $aa * ( $y - 0.5 ) ) > ( $bb * ( $x + 1 ) ) ) {

        ### assert: $d == ($x+1)**2 * $bb + ($y-.5)**2 * $aa - $aa * $bb
        if( $d < 0 ) {
            if (! $fill) {
                # unfilled draws each pixel, but filled waits until stepping
                # down "--$y" and then draws whole horizontal line
                &$ellipse_point();
            }
            $d += ( $bb * ( ( 2 * $x ) + 3 ) ) ;
            ++$x ;
        }
        else {
            &$ellipse_point();
            $d += ( ( $bb * ( (  2 * $x ) + 3 ) ) +
                    ( $aa * ( ( -2 * $y ) + 2 ) ) ) ;
            ++$x ;
            --$y ;
        }
    }

    # switch to d2 = E(x+1/2,y-1) by adding E(x+1/2,y-1) - E(x+1,y-1/2)
    $d += $aa*(.75-$y) - $bb*($x+.75);
    ### assert: $d == $bb*($x+0.5)**2 + $aa*($y-1)**2 - $aa*$bb

    ### second loop at: "$x, $y"

    while( $y >= 1 ) {
        &$ellipse_point();
        if( $d < 0 ) {
            $d += ( $bb * ( (  2 * $x ) + 2 ) ) +
              ( $aa * ( ( -2 * $y ) + 3 ) ) ;
            ++$x ;
            --$y ;
        }
        else {
            $d += ( $aa * ( ( -2 * $y ) + 3 ) ) ;
            --$y ;
        }
        ### assert: $d == $bb*($x+0.5)**2 + $aa*($y-1)**2 - $aa*$bb
    }

    # loop ends with y=0 or y=0.5 according as the height is odd or even,
    # leaving one or two middle rows to draw out to x0 and x1 edges
    ### assert: $y == $b - int($b)

    if ($fill) {
        ### middle fill: "y ".($oy-$y)." to ".($oy+$y)
        $self->rectangle( $x0, $oy - $y,
                          $x1, $oy + $y,
                          $colour, 1 ) ;
    } else {
        # middle tails from $x out to the left/right edges
        # $x can be several pixels less than $a if small height large width
        ### tail: "y=$y, left $x0 to ".($ox-$x).", right ".($ox+$x)." to $x1"
        $self->rectangle( $x0,      $oy - $y,  # left
                          $ox - $x, $oy + $y,
                          $colour, 1 ) ;
        $self->rectangle( $ox + $x, $oy - $y,  # right
                          $x1,      $oy + $y,
                          $colour, 1 ) ;
    }
}

sub rectangle { # Object method
  my ($self, $x0, $y0, $x1, $y1, $colour, $fill) = @_;

  if ($x0 == $x1) {
    # vertical line only
    $self->line( $x0, $y0, $x1, $y1, $colour ) ;

  } else {
    if ($fill) {
      for( my $y = $y0 ; $y <= $y1 ; $y++ ) {
        $self->line( $x0, $y, $x1, $y, $colour ) ;
      }

    } else { # unfilled

      $self->line( $x0, $y0,
                   $x1, $y0, $colour ) ;   # top
      if (++$y0 <= $y1) {
        # height >= 2
        if ($y0 < $y1) {
          # height >= 3, verticals
          $self->line( $x0, $y0,
                       $x0, $y1-1, $colour ) ;  # left
          $self->line( $x1, $y0,
                       $x1, $y1-1, $colour ) ;  # right
        }
        $self->line( $x1, $y1,
                     $x0, $y1, $colour ) ;  # bottom
      }
    }
  }
}

sub diamond {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### diamond(): "$x1,$y1, $x2,$y2, $colour fill=".($fill||0)

  ### assert: $x2 >= $x1
  ### assert: $y2 >= $y1

  my $w = $x2 - $x1;
  my $h = $y2 - $y1;
  if ($w < 2 || $h < 2) {
    $self->rectangle ($x1,$y1, $x2,$y2, $colour, 1);
    return;
  }
  $w = int ($w / 2);
  $h = int ($h / 2);
  my $x = $w;  # middle
  my $y = 0;   # top

  ### $w
  ### $h
  ### x1+x: $x1+$w
  ### x2-x: $x2-$w
  ### y1+y: $y1+$h
  ### y2-y: $y2-$h

  my $draw;
  if ($fill) {
    $draw = sub {
      ### draw across: "$x,$y"
      $self->line ($x1+$x,$y1+$y, $x2-$x,$y1+$y, $colour); # upper
      $self->line ($x1+$x,$y2-$y, $x2-$x,$y2-$y, $colour); # lower
    };
  } else {
    $draw = sub {
      ### draw: "$x,$y"
      $self->xy ($x1+$x,$y1+$y, $colour); # upper left
      $self->xy ($x2-$x,$y1+$y, $colour); # upper right

      $self->xy ($x1+$x,$y2-$y, $colour); # lower left
      $self->xy ($x2-$x,$y2-$y, $colour); # lower right
    };
  }

  if ($w > $h) {
    ### shallow ...

    my $rem = int($w/2) - $w;
    ### $rem

    while ($x > 0) {
      ### at: "x=$x  rem=$rem"

      if (($rem += $h) >= 0) {
        &$draw();
        $y++;
        $rem -= $w;
        $x--;
      } else {
        if (! $fill) { &$draw() }
        $x--;
      }
    }

  } else {
    ### steep ...

    # when $h is odd bias towards pointier at the narrower top/bottom ends
    my $rem = int(($h-1)/2) - $h;
    ### $rem

    while ($y < $h) {
      ### $rem
      &$draw();

      if (($rem += $w) >= 0) {
        $rem -= $h;
        $x--;
        ### x inc to: "x=$x  rem $rem"
      }
      $y++;
    }
  }

  ### final: "$x,$y"

  # middle row if $h odd, or middle two rows if $h even
  # done explicitly rather than with &$draw() so as not to draw the middle
  # row twice when $h odd
  if ($fill) {
    $self->rectangle ($x1,$y1+$h, $x2,$y2-$h, $colour, 1);
  } else {
    $self->rectangle ($x1,$y1+$h, $x1+$x,$y2-$h, $colour, 1);  # left
    $self->rectangle ($x2-$x,$y1+$h, $x2,$y2-$h, $colour, 1);  # right
  }
}

sub add_colours {
  # my ($self, $colour, $colour, ...) = @_;
}

1 ;


__END__

=head1 NAME

Image::Base - base class for loading, manipulating and saving images.

=head1 SYNOPSIS

 # base class only
 package My::Image::Class;
 use base 'Image::Base';

=head1 DESCRIPTION

This is a base class for image.  It shouldn't be used directly.  Known
inheritors are C<Image::Xbm> and C<Image::Xpm> and in see L</SEE ALSO>
below.

    use Image::Xpm ;

    my $i = Image::Xpm->new( -file => 'test.xpm' ) ;
    $i->line( 1, 1, 3, 7, 'red' ) ;
    $i->ellipse( 3, 3, 6, 7, '#ff00cc' ) ;
    $i->rectangle( 4, 2, 9, 8, 'blue' ) ;

Subclasses like C<Image::Xpm> and C<Image::Xbm> are stand-alone Perl code
implementations of the respective formats.  They're good for drawing and
manipulating image files with a modest amount of code and dependencies.

Other inheritors like C<Image::Base::GD> are front-ends to big image
libraries.  They can be handy for pointing generic C<Image::Base> style code
at a choice of modules and supported file formats.  Some inheritors like
C<Image::Base::X11::Protocol::Drawable> even go to a window etc for direct
display.

=head2 More Methods

If you want to create your own algorithms to manipulate images in terms of
(x,y,colour) then you could extend this class (without changing the file),
like this:

    # Filename: mylibrary.pl
    package Image::Base ; # Switch to this class to build on it.
    
    sub mytransform {
        my $self  = shift ;
        my $class = ref( $self ) || $self ;

        # Perform your transformation here; might be drawing a line or filling
        # a rectangle or whatever... getting/setting pixels using $self->xy().
    }

    package main ; # Switch back to the default package.

Now if you C<require> mylibrary.pl after you've C<use>d Image::Xpm or any
other Image::Base inheriting classes then all these classes will inherit your
C<mytransform()> method.

=head1 FUNCTIONS

=head2 new_from_image()

    my $bitmap = Image::Xbm->new( -file => 'bitmap.xbm' ) ;
    my $pixmap = $bitmap->new_from_image( 'Image::Xpm', -cpp => 1 ) ;
    $pixmap->save( 'pixmap.xpm' ) ;

Note that the above will only work if you've installed Image::Xbm and
Image::Xpm, but will work correctly for any image object that inherits from
Image::Base and respects its API.

You can use this method to transform an image to another image of the same
type but with some different characteristics, e.g.

    my $p = Image::Xpm->new( -file => 'test1.xpm' ) ;
    my $q = $p->new_from_image( ref $p, -cpp => 2, -file => 'test2.xpm' ) ;
    $q->save ;

=head2 line()

    $i->line( $x0, $y0, $x1, $y1, $colour ) ;

Draw a line from point ($x0,$y0) to point ($x1,$y1) in colour $colour.

                ***                         
           *****                            
       ****                                 
    ***                                     

=head2 ellipse()

    $i->ellipse( $x0, $y0, $x1, $y1, $colour ) ;
    $i->ellipse( $x0, $y0, $x1, $y1, $colour, $fill ) ;

Draw an oval enclosed by the rectangle whose top left is ($x0,$y0) and bottom
right is ($x1,$y1) using a line colour of $colour.  If optional argument
C<$fill> is true then the ellipse is filled.

       *********                            
     **         **                          
    *             *                         
     **         **                          
       *********                            

=head2 rectangle()

    $i->rectangle( $x0, $y0, $x1, $y1, $colour ) ;
    $i->rectangle( $x0, $y0, $x1, $y1, $colour, $fill ) ;

Draw a rectangle whose top left is ($x0,$y0) and bottom right is ($x1,$y1)
using a line colour of $colour. If C<$fill> is true then the rectangle will be
filled.

    ***************                         
    *             *                         
    *             *                         
    *             *                         
    ***************                         

=head2 diamond()

    $i->diamond( $x0, $y0, $x1, $y1, $colour ) ;
    $i->diamond( $x0, $y0, $x1, $y1, $colour, $fill ) ;

Draw a diamond shape within the rectangle top left ($x0,$y0) and bottom
right ($x1,$y1) using a $colour.  If optional argument C<$fill> is true
then the diamond is filled.  For example

           ***        
       ****   ****
    ***           ***
       ****   ****
           ***        

=head2 new()

Virtual - must be overridden.

Recommend that it at least supports C<-file> (filename), C<-width> and
C<-height>.

=head2 new_from_serialised()

Not implemented. Recommended for inheritors. Should accept a string serialised
using serialise() and return an object (reference).

=head2 serialise()

Not implemented. Recommended for inheritors. Should return a string
representation (ideally compressed).

=head2 get()
     
    my $width = $i->get( -width ) ;
    my( $hotx, $hoty ) = $i->get( -hotx, -hoty ) ;

Get any of the object's attributes. Multiple attributes may be requested in a
single call.

See C<xy> get/set colours of the image itself.

=head2 set()

Virtual - must be overridden.

Set any of the object's attributes. Multiple attributes may be set in a single
call; some attributes are read-only.

See C<xy> get/set colours of the image itself.

=head2 xy()

Virtual - must be overridden. Expected to provide the following functionality:

    $i->xy( 4, 11, '#123454' ) ;    # Set the colour at point 4,11
    my $colour = $i->xy( 9, 17 ) ;  # Get the colour at point 9,17

Get/set colours using x, y coordinates; coordinates start at 0. 

When called to set the colour the value returned is class specific; when
called to get the colour the value returned is the colour name, e.g. 'blue' or
'#f0f0f0', etc, e.g.

    $colour = xy( $x, $y ) ;  # e.g. #123456 
    xy( $x, $y, $colour ) ;   # Return value is class specific

We don't normally pick up the return value when setting the colour.

=head2 load()

Virtual - must be overridden. Expected to provide the following functionality:

    $i->load ;
    $i->load( 'test.xpm' ) ;

Load the image from the C<-file> attribute filename.  Or if a filename
parameter is given then set C<-file> to that name and load it.

=head2 save()

Virtual - must be overridden. Expected to provide the following functionality:

    $i->save ;
    $i->save( 'test.xpm' ) ;

Save the image to the C<-file> attribute filename.  Or if a filename
parameter is given then set C<-file> to that name and save to there.

The save format depends on the C<Image::Base> subclass.  Some implement a
C<-file_format> attribute if multiple formats can be saved.

=head2 add_colours()

Add colours to the image palette, if applicable.

    $i->add_colours( $name, $name, ...)

The drawing functions add colours as necessary, so this is just a way to
pre-load the palette.

C<add_colours()> does nothing for images which don't have a palette or can't
take advantage of pre-loading colour names.  The base code in C<Image::Base>
is a no-op.

=head1 ATTRIBUTES

The attributes for C<new()>, C<get()> and C<set()> are up to the subclasses,
but the common settings, when available, include

=over

=item C<-width> (integers)

=item C<-height>

The size of the image.  These might be create-only with C<new()> taking a
size which is then fixed.  If the image can be resized then C<set()> of
C<-width> and/or C<-height> does a resize.

=item C<-file> (string)

Set by C<new()> reading a file, or C<load()> or C<save()> if passed a
filename, or just by C<set()> ready for a future C<load()> or C<save()>.

=item C<-file_format> (string)

The name of the file format loaded or to save as.  This is generally an
abbreviation like "XPM", set by C<load()> or C<set()> and then used by
C<save()>.

=item C<-hotx> (integers, or maybe -1 or maybe C<undef>)

=item C<-hoty>

The coordinates of the "hotspot" position.  Images which can be a mouse
cursor or similar have a position within the image which is the active pixel
for clicking etc.  For example XPM and CUR (cursor form of ICO) formats have
hotspot positions.

=item C<-zlib_compression> (integer -1 to 9, or C<undef>)

The compression level for images which use Zlib, such as PNG.  0 is no
compression, 9 is maximum compression.  -1 is the Zlib compiled-in default
(usually 6).  C<undef> means no setting to use an image library default if
it has one, or the Zlib default.

For reference, PNG format doesn't record the compression level used in the
file, so for it C<-zlib_compression> can be C<set()> to control a C<save()>,
but generally won't read back from a C<load()>.

=item C<-quality_percent> (integer 0 to 100, or C<undef>)

The quality level for saving lossy image formats such as JPEG.  0 is the
worst quality, 100 is the best.  Lower quality should mean a smaller file,
but fuzzier.  C<undef> means no setting which gives some image library
default.

=back

=head1 ALGORITHMS

=head2 Lines

Sloping lines are drawn by a basic Bressenham line drawing algorithm with
integer-only calculations.  It ends up drawing the same set of pixels no
matter which way around the two endpoints are passed.

Would there be merit in rounding odd numbers of pixels according to which
way around line ends are given?  Eg. a line 0,0 to 4,1 might do 2 pixels on
y=0 and 3 on y=1, but 4,1 to 0,0 the other way around.  Or better to have
consistency either way around?  For reference, in the X11 drawing model the
order of the ends doesn't matter for "wide" lines, but for
implementation-dependent "thin" lines it's only encouraged, not required.

=head2 Ellipses

Ellipses are drawn with the midpoint ellipse algorithm.  This algorithm
chooses between points x,y or x,y-1 according to whether the position
x,y-0.5 is inside or outside the ellipse (and similarly x+0.5,y on the
vertical parts).

The current ellipse code ends up with 0.5's in the values, which means
floating point, but is still exact since binary fractions like 0.5 are
exactly representable.  Some rearrangement and factors of 2 could make it
all-integer.  The "discriminator" in the calculation may exceed 53-bits of
float mantissa at around 160,000 pixels wide or high.  That might affect the
accuracy of the pixels chosen, but should be no worse than that.

=head2 Diamond

The current code draws a diamond with the Bressenham line algorithm along
each side.  Just one line is calculated and is then replicated to the four
sides, which ensures the result is symmetric.  Rounding in the line (when
width not a multiple or height, or vice versa) is biased towards making the
pointier vertices narrower.  That tends to look better, especially when the
diamond is small.

=head2 Image Libraries

The subclasses like GD or PNGwriter which are front-ends to other drawing
libraries don't necessarily use these base algorithms, but can be expected
to something sensible within the given line endpoints or ellipse bounding
box.  (Among the image libraries it's surprising how variable the quality of
the ellipse drawing is.)

=head1 SEE ALSO

L<Image::Xpm>,
L<Image::Xbm>,
L<Image::Pbm>,
L<Image::Base::GD>,
L<Image::Base::Imager>,
L<Image::Base::Imlib2>,
L<Image::Base::Magick>,
L<Image::Base::PNGwriter>,
L<Image::Base::SVG>,
L<Image::Base::SVGout>,
L<Image::Base::Text>,
L<Image::Base::Multiplex>

L<Image::Base::Gtk2::Gdk::Drawable>,
L<Image::Base::Gtk2::Gdk::Image>,
L<Image::Base::Gtk2::Gdk::Pixbuf>,
L<Image::Base::Gtk2::Gdk::Pixmap>,
L<Image::Base::Gtk2::Gdk::Window>

L<Image::Base::Prima::Drawable>,
L<Image::Base::Prima::Image>

L<Image::Base::Tk::Canvas>,
L<Image::Base::Tk::Photo>

L<Image::Base::Wx::Bitmap>,
L<Image::Base::Wx::DC>,
L<Image::Base::Wx::Image>

L<Image::Base::X11::Protocol::Drawable>,
L<Image::Base::X11::Protocol::Pixmap>,
L<Image::Base::X11::Protocol::Window>

C<http://user42.tuxfamily.org/image-base/index.html>

=head1 AUTHOR

Mark Summerfield. I can be contacted as <summer@perlpress.com> -
please include the word 'imagebase' in the subject line.

=head1 COPYRIGHT

Copyright (c) Mark Summerfield 2000. All Rights Reserved.

Copyright (c) Kevin Ryde 2010, 2011, 2012.

This module may be used/distributed/modified under the LGPL. 

=cut

# Local variables:
# cperl-indent-level: 4
# End:
