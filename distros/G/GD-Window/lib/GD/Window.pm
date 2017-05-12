package GD::Window;

use 5.008006;
use strict;
use warnings;
use Carp qw( croak );
use vars qw/$VERSION $AUTOLOAD/;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';


my %imWindowedFuncs = (
  setPixel            => {x => [0],       'y' => [1]},
  line                => {x => [0,2],     'y' => [1,3]},
  dashedLine          => {x => [0,2],     'y' => [1,3]},
  rectangle           => {x => [0,2],     'y' => [1,3]},
  filledRectangle     => {x => [0,2],     'y' => [1,3]},
  ellipse             => {x => [0],       'y' => [1],         w => [2],          h => [3]},
  filledEllipse       => {x => [0],       'y' => [1],         w => [2],          h => [3]},
  arc                 => {x => [0],       'y' => [1],         w => [2],          h => [3]},
  filledArc           => {x => [0],       'y' => [1],         w => [2],          h => [3]},
  fill                => {x => [0],       'y' => [1]},
  fillToBorder        => {x => [0],       'y' => [1]},
  copy                => {x => [1],       'y' => [2]},
  copyMerge           => {x => [1],       'y' => [2]},
  copyMergeGray       => {x => [1],       'y' => [2]},
  copyResized         => {x => [1],       'y' => [2],         w => [5],          h => [6]},
  copyResampled       => {x => [1],       'y' => [2],         w => [5],          h => [6]},
  copyRotated         => {x => [1],       'y' => [2]},
  string              => {x => [1],       'y' => [2]},
  stringUp            => {x => [1],       'y' => [2]},
  char                => {x => [1],       'y' => [2]},
  charUp              => {x => [1],       'y' => [2]},
  stringFT            => {x => [4],       'y' => [5]},
  stringFTCircle      => {x => [0],       'y' => [1]},
  clip                => {x => [0,2],     'y' => [1,3]},
);

my %imWindowedPolyFuncs = (openPolygon => 1,
                           unclosedPolygon => 1,
                           filledPolygon => 1);


my $invertY_g = 0;


sub new {
    my $that = shift;
    my $class = ref($that) || $that;
    my ($im, $imX1, $imY1, $imX2, $imY2, 
        $winX1, $winY1, $winX2, $winY2, 
        %args) = @_;

    if (scalar(@_) < 9) {
      croak "Missing some arguments for new GD::Window";
    }

    # Fill in the window's boundary
    my $self = { im => $im,
                 minX => $winX1 > $winX2 ? $winX2 : $winX1,
                 minY => $winY1 > $winY2 ? $winY2 : $winY1,
                 maxX => $winX1 > $winX2 ? $winX1 : $winX2,
                 maxY => $winY1 > $winY2 ? $winY1 : $winY2,
                 imMinX => $imX1 > $imX2 ? $imX2 : $imX1,
                 imMinY => $imY1 > $imY2 ? $imY2 : $imY1,
                 imMaxX => $imX1 > $imX2 ? $imX1 : $imX2,
                 imMaxY => $imY1 > $imY2 ? $imY1 : $imY2,
                 passThroughIfUnsupported => $args{passThrough},
                 useImage => $args{useImage},
                 invertY => defined $args{invertY} ? $args{invertY} : $invertY_g,
    };

    if ($self->{useImage}) {
      # Need to make our own internal image
      $self->{parentIm} = $im;
      $self->{im} = GD::Image->new(($self->{maxX} - $self->{minX}), ($self->{maxY} - $self->{minY}), 1);
      $self->{scaleX} = 1;
      $self->{scaleY} = 1;
      $self->{srcImMinX} = $self->{imMinX};
      $self->{srcImMinY} = $self->{imMinY};
      $self->{imMinX} = 0;
      $self->{imMinY} = 0;
    }
    else {
      $self->{scaleX} = ($self->{imMaxX} - $self->{imMinX})/($self->{maxX} - $self->{minX});
      $self->{scaleY} = ($self->{imMaxY} - $self->{imMinY})/($self->{maxY} - $self->{minY});
    }

    # print "PostSub: $postSub\n";
    if ($@) {
      die "Failed eval of autoloaded sub: $@";
    }

    bless ($self, $class);
    return $self;
}


##
# The autoload function catches all the supported image functions and
# creates the appropriate transformations for them.
#
# If passThrough is defined on window creation, then unsupported
# functions will simply be forwarded to the image.  Otherwise, 
# we will croak.
##
sub AUTOLOAD {
  my ($self) = @_;
  my ($name) = ($AUTOLOAD =~ /::([^:]+)$/);
  my @args = @_;

  if (exists $imWindowedFuncs{$name}) {
    my $fi = $imWindowedFuncs{$name};

    # Create the function that should be called
    my $body = " my \$s = shift;my \@args = \@_;\n";

    foreach my $dim (qw(x y w h)) {
      if ($fi->{$dim}) {
        foreach my $idx (@{$fi->{$dim}}) {
          $body .= " \$args[$idx] = \$s->translate". uc($dim) ."(\$args[$idx]);\n";
        }
      }
    }
    # $body .= "   print \"calling $name with \$s->{im} -> \@args\\n\"; my \$res = \$s->{im}->$name(\@args); \$s->postRenderAdjustment(); return \$res; \n";
    $body .= "   my \$res = \$s->{im}->$name(\@args); \$s->postRenderAdjustment(); return \$res; \n";
    # print "Eval: $body\n";
    eval "sub $name { $body }; return $name(\@args);";
    if ($@) {
      die "Failed eval of autoloaded sub: $@";
    }
  }
  elsif (exists $imWindowedPolyFuncs{$name}) {

    my $body = qq ^
  my (\$self, \$poly, \$color) = \@_;
  my \$transPoly = GD::Polygon->new;

  # Need to go through all the points and adjust them
  foreach my \$vertex (\$poly->vertices) {
    \$transPoly->addPt(\$self->translateX(\$vertex->[0]), \$self->translateY(\$vertex->[1]));
  }
  \$self->{im}->$name(\$transPoly, \$color);
    ^;
#    print "Adding \@{\$vertex}\n";
#  my \@v = \$transPoly->vertices;
#foreach my \$v (\@v) {
#  print "poly: \@{\$v}\n";
#}

#    print "BODY: $body\n";
    eval "sub $name { $body }; return $name(\@args);";
    if ($@) {
      die "Failed eval of autoloaded sub: $@";
    }

  }
  else {
    if ($self->{passThroughIfUnsupported} || $self->{useImage}) {
      eval("sub $name { my \$s = shift; my \$res = \$s->{im}->$name(\@_); \$s->postRenderAdjustment(); return \$res;}; return $name(\@_);");
      if ($@) {
        die "Failed eval of autoloaded sub: $@";
      }
    }
    else {
      croak "Sub $name is not supported by GD::Window";
    }
  }
}



##
# Methods that can't be handled by the AUTOLOAD
##
sub boundsSafe {
  my ($self, $x, $y) = @_;
  return ($x >= $self->{minX} &&
          $x <= $self->{maxX} && 
          $y >= $self->{minY} &&
          $y <= $self->{maxY}); 
}

sub bounds {
  my ($self) = @_;
  if (!$self->{invertY}) {
    return($self->{minX},
           $self->{minY},
           $self->{maxX},
           $self->{maxY});
  }
  else {
    return($self->{minX},
           $self->{maxY},
           $self->{maxX},
           $self->{minY});
  }
}


sub dimensions {
  my ($self) = @_;
  return($self->{maxX} - $self->{minX},
         $self->{maxY} - $self->{minY});
}


##
# Public Methods for changing globals
##
sub invertY {
  my ($that, $val) = @_;

  if (ref($that)) {
    $that->{invertY} = $val;
  }
  else {
    $invertY_g = $val;
  }

}


##
# Private Methods
##
sub translateX {
  my ($self, $x) = @_;
  my $newX = ($x - $self->{minX}) * $self->{scaleX} + $self->{imMinX};
  # print "translate from $x to $newX, $self->{scaleX}, $self->{minX}, $self->{imMinX}\n";
  return $newX;
}

sub translateY {
  my ($self, $y) = @_;
  if ($self->{invertY}) {
    $y = $self->{maxY} - $y;
  }
  my $newY = ($y - $self->{minY}) * $self->{scaleY} + $self->{imMinY};
  # print "translate from $y to $newY, $self->{scaleY}\n";
  return $newY;
}

sub translateW {
  my ($self, $w) = @_;
  return $w * $self->{scaleX};
}

sub translateH {
  my ($self, $h) = @_;
  return $h * $self->{scaleY};
}

sub postRenderAdjustment {
  my $self = shift;
  return if !$self->{useImage};
  $self->{parentIm}->copyResampled(
    $self->{im}, $self->{srcImMinX}, $self->{srcImMinY}, 0, 0,
    ($self->{imMaxX} - $self->{srcImMinX}), ($self->{imMaxY} - $self->{srcImMinY}),
    ($self->{maxX} - $self->{minX}), ($self->{maxY} - $self->{minY}));
};


sub DESTROY {}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

GD::Window - Allows the creation of windows within an GD image that
have a different coordinate system.

=head1 SYNOPSIS

  use GD::Window;

  # Globally treat the Y-axis as increasing in the upward direction
  # This can be set on a per-window basis too
  GD::Window->invertY(1);

  my $im = GD::Image->new(100, 100);

  # Create a window that will display from (10,25) to (90,75) in the 
  # image, but the window itself will have the coordinate system
  # (-1000,-1000) to (1000, 1000).  invertY is turned off, so Y=-1000 will be
  # the very top edge of the window (25 in the image)
  my $win = GD::Window->new($im,
                            10, 25, 90, 75,   
                            -1000, -1000, 1000, 1000, 
                            invertY => 0);

  my $col = $im->colorAllocateAlpha(75,  75, 75, 10);

  # Draw a line from 0,0 to 500, 500 in the window.  This will 
  # show up as a line from 50,50 to 62,62 in the image
  $win->line(0,0, 500, 500, $col);


=head1 DESCRIPTION

GD::Window is a way to have some abstraction of drawing coordinates
from the underlying image.  An obvious example where this is useful
is in cases where it is necessary to plot some values on a graph. 
The graph area within the image can be represented as a window with the
exact dimensions as the graph itself allowing for easy plotting of the 
values.  For example, if the x-axis has points that are seconds since
epoch and the plot is constrained to a known time-period, then the
windows X boundaries can be set to the start of the time-period and
the end of the time period.

There are two very different ways to render the window onto the image.
By default, the window simply transforms the X,Y coordinates 
(and some size values if necessary) and then calls the image's method
with the transformed coordinates.  In the other mode (useImage mode), 
a new image will be created to behind the scenes and it will be merged
onto the main image.  This will provide more accurate scaling and will
provide clipping on the window edges, but it is slower and can use
more memory.

To control which mode you use, an optional 'useImage => (0|1)' parameter can
be passed to new to specify the mode.  'useImage => 1' will put the
window into useImage mode.

It is also possible to layer windows on top of each other.  Instead of
passing an image reference to GD::Window::new, a window reference can
be passed.  This allows a heirchy of windows to be built.


=head1 Methods

=head2 new

new(<$image|$win>, imX1, imY1, imX2, imY2, winX1, winY1, winX2, winY2, %options)

Create a new window that will be placed at (imX1, imY1), (imX2, imY2) in the 
specified image or window.  The window itself will have the coordinate system
with (winX1, winY1) at one corner and (winX2, winY2) at the other corner.


The list of options are:

=over 12

=item useImage

Instead of simply doing coordinate, height and width translations, draw to 
a separate image with the window's coordinate system and then put that image
into the main image.  This will achieve clipping for items that are
outside the bounds of the window.  Note that this will use a copyResampled
function to put the window's image into the main image.  Note also that if the
window's coordinate system is very large, the window's image will consume a lot
of memory.

=item passThrough

If true ('passThrough => 1'), GD::Window will not complain about unsupported
methods being called and will instead just pass them on to the image object.
This can be useful if an existing program is being retrofitted with GD::Window
and it is easier to just change the existing $image variable to point to 
a GD::Window object.

=item invertY

By default, GD's Y coordinates increase from the top edge of the image down
towards the bottom edge of the image.  If this option is set, then the
Y axis will be flipped and Y coordinates will increase going up the image instead.

=back 

=head2 image methods

The following GD methods are supported within a GD::Window.  They take
exactly the same paramters as the normal image methods, but will do the 
appropriate scaling before rendering them.

  setPixel        
  line            
  dashedLine      
  rectangle       
  filledRectangle 
  ellipse         
  filledEllipse   
  arc             
  filledArc       
  fill            
  fillToBorder    
  copy            
  copyMerge       
  copyMergeGray   
  copyResized     
  copyResampled   
  copyRotated     
  string          
  stringUp        
  char            
  charUp          
  stringFT        
  stringFTCircle  
  clip            

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<GD>, L<GD::Image>

=head1 BUGS

Test suite is almost non-existant at the moment.  Tests are being added...

=head1 AUTHOR

Edward Funnekotter, E<lt>efunneko+cpan@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Edward Funnekotter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
