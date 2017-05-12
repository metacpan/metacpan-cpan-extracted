# Hibert.pm Perl Implementation of Hilberts space filling Curve
package Math::Curve::Hilbert;


=head1 NAME

Math::Curve::Hilbert - Perl Implementation of Hilberts space filling Curve

=head1 SYNOPSIS

  use Math::Curve::Hilbert;

  # get object representing 8x8 curve with a step of 10 (i.e. draw 80x80 pixels)
  my $hilbert = Math::Curve::Hilbert->new( direction=>'up', max=>3, clockwise=>1, step=>10);

  # get a point from coordinates
  my $point = $hilbert->PointFromCoordinates(20,60);

  # get coordinates from a point
  my ($x,$y) = $hilbert->CoordinatesFromPoint($point);


  # get range(s) from box
  my @ranges = $hilbert->RangeFromCoordinates($x1,$y1,$x2,$y2);

  #
  # draw image representing curve

  use GD;
  # create a new image
  my $im = new GD::Image(300,300);
  my $black = $im->colorAllocate(0,0,0);
  my $blue = $im->colorAllocate(0,0,255);

  my $count = 0;
  my ($x1,$y1) = $hilbert->CoordinatesFromPoint($count++);
  while ( ($hilbert->CoordinatesFromPoint($count))[0] ) {
      my ($x2,$y2) = $hilbert->CoordinatesFromPoint($count++);
      $im->line($x1,$y1,$x2,$y2,$black);
      ($x1,$y1) = ($x2,$y2);
  }

=head1 DESCRIPTION

The Hilbert Curve module provides some useful functions using Hilberts Space-filling Curve. This is handy for things like Dithering, Flattening n-dimensional data, fractals - all kind of things really.

"A Space Filling Curve is a special fractal curve which has the following basic characteristics:
 ­ it covers completely an area, a volume or a hyper-volume in a 2-d, 3-d or N-d space respectively,
 ­ each point is visited once and only once (the curve does not cross itself), and
 ­ neighbor points in the native space are likely to be neighbors in the space filling curve."
definition from Multiple Range Query Optimization in Spatial Databases, Apostolos N. Papadopoulos and Yannis Manolopoulos

Other space filling curves include The Peano and Morton or Z-order curves. There is also the Hilbert II curve which has an 'S' shape rather than a 'U' shape. The Hilbert curve can also be applied to 3 dimensions, but this module only supports 2 dimensions.

Like most space filling curves, the area must be divided into 2 to the power of N parts, such as 8, 16, 32, etc

=head2 EXPORT

None by default.

=cut

use strict;

use Data::Dumper;

use vars qw(@ISA $VERSION);
$VERSION = '0.04';

=head1 METHODS

=head2 new

  # get object representing 8x8 curve with a step of 10 (i.e. draw 80x80 pixels)
  my $hilbert = Math::Curve::Hilbert->new( direction=>'up', max=>3, clockwise=>1, step=>10);

  direction specifies which direction the curve follows :

  up (clockwise) : up, right, down
  down (clockwise ) : down, right, up
  left (clockwise) : left, up, right
  right (clockwise) : right, down, left

  clockwise specifies if the curve moves clockwise or anti-clockwise, the default is clockwise

  max specifies the size of the grid to plot in powers of 2 - max=>2 would be a 4x4 grid, max=>4 would be 16 x 16 grid

  step specifies how large a step should be (used in drawing the curve), the default is 1

  X and Y allow you to specify a starting X and Y coordinate by passing a reference to a the value

=cut


sub new {
    my ($class,%options) = @_;
    $options{clockwise} = 1 unless (defined $options{clockwise});
    $options{step} ||= 1;
    $options{level} ||= 0;
    my $self = bless({%options},ref $class || $class);
    my $maxsize = (2 ** $options{max}) * $options{step};
    my $minsize = $options{step};
    my $X = $options{X};
    my $Y = $options{Y};
 DIRECTION: {
	if (lc$options{direction} =~ m/up/) {
	    $X ||= ( $options{clockwise} ) ? $minsize : $maxsize ;
	    $Y ||= $maxsize;
	    $options{X} = \$X;
	    $options{Y} = \$Y ;
	    $self->{coords} = $self->up(%options), last;
	}
	if (lc$options{direction} =~ m/down/) {
	    $X ||= ( $options{clockwise} ) ?  $maxsize: $minsize ;
	    $Y ||= $minsize ;
	    $options{X} = \$X;
	    $options{Y} = \$Y ;
	    $self->{coords} =  $self->down(%options), last;
	}
	if (lc$options{direction} =~ m/left/) {
	    $X ||= $maxsize;
	    $Y ||= ( $options{clockwise} ) ? $maxsize : $minsize ;
	    $options{X} = \$X;
	    $options{Y} = \$Y ;
	    $self->{coords} = $self->left(%options), last;
	}
	if (lc$options{direction} =~ m/right/) {
	    $X ||= $minsize;
	    $Y ||= ( $options{clockwise} ) ? $minsize : $maxsize ;
	    $options{X} = \$X;
	    $options{Y} = \$Y ;
	    $self->{coords} = $self->right(%options), last;
	}
    }; # end of DIRECTION
    return $self;
}

=head2 PointFromCoordinates

  my $point = $hilbert->PointFromCoordinates(20,60);

=cut

sub PointFromCoordinates {
    my ($self,$x,$y) = @_;
    my $point = $self->{curve}{"$x:$y"};
    return $point;
}

=head2 CoordinatesFromPoint

  my ($x1,$y1) = $hilbert->CoordinatesFromPoint($point);

=cut

sub CoordinatesFromPoint {
    my ($self,$point) = @_;
    return ($self->{coords}[$point]{X},$self->{coords}[$point]{Y});
}

=head2 RangeFromCoordinates

  # get range(s) from box
  my @ranges = $hilbert->RangeFromCoordinates($x1,$y1,$x2,$y2);

=cut

sub RangeFromCoordinates {
    my ($self,$x1,$y1,$x2,$y2) = @_;

    # get point from top left coordinate
    my $startpoint;
    my $nextpoint;
    my %rangepoints;
    my @ranges;

    my ($xx,$yy) = ($x1,$y1);
    while ( ($xx <= $x2) && ($yy <= $y2) ) {
	$startpoint = $self->{curve}{"$xx:$yy"};
	unless (defined $rangepoints{$startpoint}) {
	    push (@ranges,$startpoint);
	    $rangepoints{$startpoint} = $#ranges;
	    $nextpoint = $startpoint;
	    my $ok = 1;
	    while ( $ok == 1 ) {
		$startpoint++;
		my ($x,$y) = ($self->{coords}[$startpoint]{X},$self->{coords}[$startpoint]{Y});
		if ($x <= $x2 && $y <= $y2 && $x >= $x1 && $y >= $y1) {
		    if ($rangepoints{$startpoint}) {
			$ranges[$rangepoints{$startpoint}] = $nextpoint;
			pop(@ranges);
			last;
		    } else {
			$rangepoints{$startpoint} = $#ranges;
			$nextpoint = $startpoint;
		    }
		} else {
		    push (@ranges,$nextpoint);
		    $rangepoints{$startpoint} = 0;
		    $ok = 0;
		}
	    }
	}
	if ($xx == $x2) {
	    if ( $yy < $y2) { $yy++; $xx = $x1; }
	    else { last; }
	} else {
	    $xx++;
	}
    }
    return @ranges;

}

################################################################################

sub up {
  my $self = shift;
  my %args = @_;
  my $coords = [];
  my $this_level = $args{level} + 1;
  my ($x,$y) = ($args{X}, $args{Y});
  my $step = $args{step} || $self->{step};
#  warn "up : x : $$x, y : $$y, step : $step, level : $this_level\n";
  if ($this_level == 1) {
      push (@$coords,{X=>$$x,Y=>$$y});
      $self->{curve}{"$$x:$$y"} = $#$coords;
  }
  if ($args{clockwise}) {
      if ($args{max} == $this_level) {
	  $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
      } else {
	  foreach (@{$self->right(X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
	  $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  foreach (@{$self->up(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
	  $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  foreach (@{$self->up(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
	  $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  foreach (@{$self->left(X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
      }
  } else {
      if ($args{max} == $this_level) {
	  $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  $$x -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
      } else {
	  foreach (@{$self->left(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
	  $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords + 1;
	  foreach (@{$self->up(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
	  $$x -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords + 1;
	  foreach (@{$self->up(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
	  $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  foreach (@{$self->right(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
      }
  }
  return $coords;
}


sub left {
  my $self = shift;
  my %args = @_;
  my $coords = [];
  my $this_level = $args{level} + 1;
  my ($x,$y) = ($args{X}, $args{Y});
  my $step = $args{step} || $self->{step};
#  warn "left : x : $$x, y : $$y, step : $step, level : $this_level\n";
  if ($this_level == 1) {
      push (@$coords,{X=>$$x,Y=>$$y});
      $self->{curve}{"$$x:$$y"} = $#$coords;
  }
  if ($args{clockwise}) {
      if ($args{max} == $this_level) {
	  $$x -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
      } else {
	  foreach (@{$self->up(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
	  $$x -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  foreach (@{$self->left(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
	  $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  foreach (@{$self->left(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
	  $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  foreach (@{$self->down(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
      }
  } else {
      if ($args{max} == $this_level) {
	  $$x -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
      } else {
	  foreach (@{$self->down(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
	  $$x -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  foreach (@{$self->left(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
	  $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  foreach (@{$self->left(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
	  $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
	  $self->{curve}{"$$x:$$y"} = $#$coords;
	  foreach (@{$self->up(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
	      push (@$coords,$_);
	      $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	  }
      }
  }
  return $coords;
}

sub right {
    my $self = shift;
    my %args = @_;
    my $coords = [];
    my $this_level = $args{level} + 1;
    my ($x,$y) = ($args{X}, $args{Y});
    my $step = $args{step} || $self->{step};
#    warn "right : x : $$x, y : $$y, step : $step, level : $this_level\n";
    if ($this_level == 1) {
	push (@$coords,{X=>$$x,Y=>$$y});
	$self->{curve}{"$$x:$$y"} = $#$coords;
    }
    if ($args{clockwise}) {
	if ($args{max} == $this_level) {
	    $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
	    $self->{curve}{"$$x:$$y"} = $#$coords;
	    $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
	    $self->{curve}{"$$x:$$y"} = $#$coords;
	    $$x -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	    $self->{curve}{"$$x:$$y"} = $#$coords;
	} else {
	    foreach (@{$self->down(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	    $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
	    foreach (@{$self->right(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	    $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
	    foreach (@{$self->right(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	    $$x -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	    foreach (@{$self->up(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	}
    } else {
	if ($args{max} == $this_level) {
	    $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
	    $self->{curve}{"$$x:$$y"} = $#$coords;
	    $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	    $self->{curve}{"$$x:$$y"} = $#$coords;
	    $$x -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	    $self->{curve}{"$$x:$$y"} = $#$coords;
	} else {
	    foreach (@{$self->up(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	    $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
	    foreach (@{$self->right(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	    $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	    foreach (@{$self->right(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	    $$x -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	    foreach (@{$self->down(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	}
    }
    return $coords;
}

sub down {
    my $self = shift;
    my %args = @_;
    my $coords = [];
    my $this_level = $args{level} + 1;
    my ($x,$y) = ($args{X}, $args{Y});
    my $step = $args{step} || $self->{step};
#    warn "down : x : $$x, y : $$y, step : $step, level : $this_level\n";
    if ($this_level == 1) {
	push (@$coords,{X=>$$x,Y=>$$y});
	$self->{curve}{"$$x:$$y"} = $#$coords;
    }
    if ($args{clockwise}) {
	if ($args{max} == $this_level) {
	    $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
	    $self->{curve}{"$$x:$$y"} = $#$coords;
	    $$x -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	    $self->{curve}{"$$x:$$y"} = $#$coords;
	    $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	    $self->{curve}{"$$x:$$y"} = $#$coords;
	} else {
	    foreach (@{$self->left(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	    $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
	    foreach (@{$self->down(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	    $$x -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	    foreach (@{$self->down(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	    $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	    foreach (@{$self->right(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	}
    } else {
	if ($args{max} == $this_level) {
	    $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
	    $self->{curve}{"$$x:$$y"} = $#$coords;
	    $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
	    $self->{curve}{"$$x:$$y"} = $#$coords;
	    $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	    $self->{curve}{"$$x:$$y"} = $#$coords;
	} else {
	    foreach (@{$self->right(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	    $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
	    foreach (@{$self->down(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	    $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
	    foreach (@{$self->down(clockwise=>0,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	    $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
	    foreach (@{$self->left(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
		push (@$coords,$_);
		$self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
	    }
	}
    }
    return $coords;
}


1;

__END__

##########################################################################

=head1 AUTHOR

A. J. Trevena, E<lt>teejay@droogs.orgE<gt>

=head1 SEE ALSO

L<perl>.

L<http://mathworld.wolfram.com/HilbertCurve.html>

=cut
