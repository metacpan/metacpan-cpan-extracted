#	Geo::SpaceManger
#
#	This package implements the Geo::SpaceManager class. This class
#	may be used to place two-dimensional rectangles without overlap
#	into a two-dimensional space. It does this by maintaining a dataset
#	of free space still available in the space and returning the
#	closest available location in which an additional rectangle
#	of a specified size may be added.

package Geo::SpaceManager;

use strict;
use warnings;
use Carp qw(carp croak);

=pod

=head1 NAME

Geo::SpaceManager - Place rectangles without overlap

=cut

# public global variables
our $VERSION = '0.93';
our $DEBUG = 0;

# private global variables
my @opposite = ( 2, 3, 0, 1 );	# opposite sides of rectangle

=head1 SYNOPSIS

 use Geo::SpaceManager;

 $sm = Geo::SpaceManager->new([0,0,100,100]);
 my $r1 = [10,10,40,30];
 my $r2 = [20,20,60,40];
 my $r3 = [50,10,80,70];
 my $r4 = [20,50,90,90];
 my $p1 = $sm->nearest($r1);  # returns [10,10,40,30];
 $sm->add($p1);
 my $p2 = $sm->nearest($r2);  # returns [20,30,60,50];
 $sm->add($p2);
 my $p3 = $sm->nearest($r3);  # returns [60,10,90,70]
 $sm->add($p3);
 my $p4 = $sm->nearest($r4);  # returns undef

=head1 DESCRIPTION

Geo::SpaceManager keeps track of the free space available in a two-dimensional
space as upright (non-rotated) rectangles are added. The module can find the 
nearest available location where a rectangle may be placed or indicate that 
the rectangle cannot be placed in any of the remaining free space.

Rectangles are specified by references to four-element arrays giving the
boundaries of the rectangle:

  [ left, bottom, right, top ]

Reflected boundary values may be used by swapping left <-> right and
top <-> bottom when specifying rectangles, but the return value of
nearest() will return a value as shown above.

=head1 CONSTRUCTOR

=head2 new

The new() constructor should be called with the rectangle representing
the entire free space to be managed. A second, optional argument turns
debugging on if it has a true value.

    my $sm = Geo::SpaceManager->new( [0, 0, 100, 100] );
    my $sm_debug = Geo::SpaceManager->new( [0, 0, 100, 100], 1 );
    
=cut

sub new
{
  my( $class, $top, $dbg ) = @_;
  croak("No space to manage in call to new") unless $top;
  $DEBUG = $dbg if defined $dbg;
  my $self = {};
  bless $self, $class;
  $top = [ @$top ];
  $self->_normalize($top);
  $self->{top} = $top;
  $self->{free} = [ $top ];
  $self->{minimum} = [ 0, 0 ];
  print "Creating manager for space [@$top]\n" if $DEBUG;
  return $self;
}

=head1 METHODS

=head2 set_minimum_size

Set the minimum size for rectangles to be added. 

The following all set the minimum size of rectangles to (10,20):

  $sm->set_minimum_size([10,20]);
  $sm->set_minimum_size([0,0,10,20]);
  $sm->set_minimum_size([10,30,20,50]);
  $sm->set_minimum_size([20,50,10,30]);

Setting a minimum size means that SpaceManager can be more efficient 
in space and time by discarding free-space areas if they are too small 
to contain any more rectangles of the minimum size.

You should set the minimum size before adding any rectangles and not
change it afterwards with another call to set_minimum_size.

=cut

sub set_minimum_size
{
  my( $self, $rec ) = @_;
  my @r;
  unless( defined $rec ) {
    carp("No minimum height and width passed to set_minimum_size");
    return;
  }
  $r[$_] = ($$rec[$_] || 0 ) for (0..3);
  $self->{minimum} = [ abs( $r[2] - $r[0] ), abs( $r[3] - $r[1] ) ];
  return 1;
}

=head2 add

Add a rectangle to the current free space. 

  $sm->add( [10,20,50,40] );

The free space will be reduced by the rectangle. The method returns 1
if successful and undef on failure. The only failures will be if the 
rectangle argument is missing or if it lies entirely outside of 
the space.

=cut

sub add
{
  my( $self, $rec ) = @_;
  
  unless( $rec and (@$rec == 4) ) {
    carp("Invalid rectangle passed to add");
    return;
  }

  print "\nAdding [@$rec] to ", scalar @{$self->{free}}, 
    " free rectangles\n" if $DEBUG;
  
  my( $left, $bottom, $right, $top ) = $self->_normalized($rec);
  my( @new_set, @reduced_set );
  
  # check if provided rectangle lies inside space
  for my $i ( 0 .. 1 ) {
    if( ($rec->[$i]   > $self->{top}->[$opposite[$i]]  ) ||
        ($rec->[$i+2] < $self->{top}->[$opposite[$i+2]]) ) {
      carp(sprintf "Rectangle [%s] is outside of space [%s]", 
        join(',',@$rec), join(',',@{$self->{top}} ) );
      return;
    }
  }

  # check to see which current free-space rectangles are intersected by new one
  foreach my $r ( @{$self->{free}} ) {
    my $reduce = 0;
    print "  Check [@$r] for reduction\n" if $DEBUG;
    
    # see if rectangles intersect
    next if( $left   >= $$r[2] );
    next if( $right  <= $$r[0] );
    next if( $bottom >= $$r[3] );
    next if( $top    <= $$r[1] );
    
    # new rectangle intersects a free-space rectangle, which must be reduced
    # determine which edges of the current free-space rectangle are 
    # intersected by the new one and form a new free-space rectangle
    # by reducing the old one to the part that is not intersected.
    
    # see if new rectangle completly surrounds free rectangle
    if( $left   <= $$r[0] &&
        $bottom <= $$r[1] &&
        $right  >= $$r[2] &&
        $top    >= $$r[3] ) {

      # new rectangle covers this free rectangle completely -- remove it
      $reduce = 1;
      print "    covered by new rectangle\n" if $DEBUG;

    }else{

      # left-reduced?
      print "    check if right edge $right in ($$r[0],$$r[2]):\n" if $DEBUG;
      if( $right < $$r[2] ) {
        my $newr = [ $right, $$r[1], $$r[2], $$r[3] ];
        print "      reduce [@$r] at $right to give [@$newr]\n" if $DEBUG;
        push( @new_set, $newr);
        $reduce = 1;
      }
      
      # top-reduced?
      print "    check if bottom edge $bottom in ($$r[1],$$r[3]):\n" if $DEBUG;
      if( $bottom > $$r[1] ) {
        my $newr = [ $$r[0], $$r[1], $$r[2], $bottom  ];
        print "      reduce [@$r] at $bottom to give [@$newr]\n" if $DEBUG;
        push( @new_set, $newr);
        $reduce = 1;
      }
  
      # right-reduced?
      print "    check if left edge $left in ($$r[0],$$r[2]):\n" if $DEBUG;
      if( $left > $$r[0] ) {
        my $newr = [ $$r[0], $$r[1], $left, $$r[3] ];
        print "      reduce [@$r] at $left to give [@$newr]\n" if $DEBUG;
        push( @new_set, $newr);
        $reduce = 1;
      }
  
      # bottom-reduced?
      print "    check if top edge $top in ($$r[1],$$r[3]):\n" if $DEBUG;
      if( $top < $$r[3] ) {
        my $newr = [ $$r[0], $top, $$r[2], $$r[3] ];
        print "      reduce [@$r] at $top to give [@$newr]\n" if $DEBUG;
        push( @new_set, $newr);
        $reduce = 1;
      }
    }
      
    # put the existing rectangle on a list of rectangles to be removed
    # if it was reduced or covered by the new one
    if( $reduce ) {
      push( @reduced_set, $r );
    }
  }
  
  if( $DEBUG ) {
    print scalar @new_set, " new rectangles, ", scalar @reduced_set,
    " rectangles to be removed\n";
  }

  # determine which of the new free-space rectangles to keep:
  
  # 1. only keep the reduced free-space rectangles if they are greater 
  #    than the minimum size (which can be zero)
  # 2. don't keep a rectangle if it is identical to one already in the list
  #    (i.e., has a lower index)
  # 3. don't keep a rectangle if it is entirely within another
  
  my @mod_new_set;
  print "  Test new candidates for inclusion:\n" if $DEBUG;
  ADD: for my $i1 ( 0 .. $#new_set ) {
    my $r1 = $new_set[$i1];
    print "    check [@$r1]\n" if $DEBUG;
    
    # skip if less than minimum size
    next if( 
      ( $$r1[2] - $$r1[0] ) < ${$self->{minimum}}[0] or 
      ( $$r1[3] - $$r1[1] ) < ${$self->{minimum}}[1]
    ); 
    
    # compare to other candidate rectangles
    for my $i2 ( 0 .. $#new_set ) {
      
      # don't compare with itself
      next if $i1 eq $i2;
      my $r2 = $new_set[$i2];
      print "      compare with [@$r2]\n" if $DEBUG;

      # see if identical to another one
      if( 
        ($$r1[0] == $$r2[0]) && 
        ($$r1[1] == $$r2[1]) && 
        ($$r1[2] == $$r2[2]) && 
        ($$r1[3] == $$r2[3]) ) {
        
        # keep the last one if they are identical
        next ADD if $i1 < $i2;

      }else{
        # skip this one if it is entirely within another one
        next ADD if( 
          ($$r1[0] >= $$r2[0]) && 
          ($$r1[1] >= $$r2[1]) && 
          ($$r1[2] <= $$r2[2]) && 
          ($$r1[3] <= $$r2[3]) );
      }
    }
    push( @mod_new_set, $r1 );
    print "    keeping [@$r1]\n" if $DEBUG;
  }

  if( $DEBUG ) {
    print "  keeping ", scalar @mod_new_set, " new rectangles\n";
    print "  deleting ", scalar @reduced_set, " current rectangles\n";
    print "  New:\n";
    foreach my $r ( @mod_new_set ) {
      print "    [@$r]\n";
    }
    print "  Delete:\n";
    foreach my $r ( @reduced_set ) {
      print "    [@$r]\n";
    }
  }

  # form the new set of free-space rectangles
  
  # delete rectangles that have been reduces
  my @new_free;
  DEL: foreach my $r ( @{$self->{free}} ) {
    foreach my $s ( @reduced_set ) {
      next DEL if( $r eq $s );
    }
    push( @new_free, $r );
    print "  keeping [@$r]\n" if $DEBUG;
  }
  
  # add reduced parts of old rectangles that have made it through
  # the selection process
  push( @new_free, @mod_new_set );

  # save the new set
  $self->{free} = \@new_free;

  if( $DEBUG ) {
    print "New Free Set (", scalar @new_free, "):\n";
    foreach my $rec ( @new_free ) {
      my $area = ( $$rec[2] - $$rec[0] )*( $$rec[3] - $$rec[1] );
      print "  [@$rec]   $area\n";
    }
    print "\n";
  }
  return 1;
}

=head2 nearest

Find the nearest location in which to place the specified rectangle.

  $r = $sm->nearest([10,30,30,50]);

The method will return a reference to an array of four scalars specifying
a rectangle of the same size as the supplied one that fits wholly into
an available free space if space can be found. The rectangle will be
a copy of the provided one if it fits as is. The method will return
undef if there is no free space that can contain the supplied rectangle.

=cut

sub nearest
{
  my( $self, $rec ) = @_;
  print "find nearest free location to contain [@$rec]\n" if $DEBUG;
  my( $best, $best_dist );
  $self->_normalize($rec);
  my $w = $$rec[2] - $$rec[0];
  my $h = $$rec[3] - $$rec[1];
  print "  width=$w, height=$h\n" if $DEBUG;

  # search every available free-space rectangle to find best fit
  foreach my $r ( @{$self->{free}} ) {
    print "  check [@$r]\n" if $DEBUG;
    return [ @$rec ] if(
      ($$rec[0] >= $$r[0]) &&
      ($$rec[1] >= $$r[1]) &&
      ($$rec[2] <= $$r[2]) &&
      ($$rec[3] <= $$r[3]) );
    
    # see if rectangle would fit
    printf "    check size against (%.2f,%.2f)\n", ($$r[2]-$$r[0]),
      ($$r[3]-$$r[1]) if $DEBUG;
    next if( $w > ( $$r[2] - $$r[0] ));
    next if( $h > ( $$r[3] - $$r[1] ));
    
    # see how far rectangle would have to be moved to be placed inside
    
    my @dif = map { $$rec[$_] - $$r[$_] } ( 0..3 );
    my @absdif = map { abs($_) } @dif;
    my $ydif = 0;
    if( ($dif[1] * $dif[3]) > 0 ) {
      $ydif = ( ($absdif[1] > $absdif[3]) ? $absdif[3] : $absdif[1] );
    }
    my $xdif = 0;
    if( ($dif[0] * $dif[2]) > 0 ) {
      $xdif = ( ($absdif[0] > $absdif[2]) ? $absdif[2] : $absdif[0] );
    }
    my $dist = $xdif * $xdif + $ydif * $ydif;
    print "    dif=[@dif], del=[$xdif,$ydif], dist=$dist\n" if $DEBUG;
    if( ! $best or ($dist < $best_dist) ) {
      $best = $r;
      $best_dist = $dist;
      print "      best so far\n" if $DEBUG;
    }
  }
  
  # quit if doesn't fit
  return undef unless $best;
  
  print "  nearest free space is [@$best]\n" if $DEBUG;
  my $r = [ @$rec ];
  
  # translate rectangle to nearest edge of nearest rectangle
  if( $$r[0] < $$best[0] ) {
    $$r[0] = $$best[0];
    $$r[2] = $$r[0] + $w;
  }elsif( $$r[2] > $$best[2] ) {
    $$r[2] = $$best[2];
    $$r[0] = $$r[2] - $w;
  }
  if( $$r[1] < $$best[1] ) {
    $$r[1] = $$best[1];
    $$r[3] = $$r[1] + $h;
  }elsif( $$r[3] > $$best[3] ) {
    $$r[3] = $$best[3];
    $$r[1] = $$r[3] - $h;
  }
  
  return $r;
}

=head2 distance

Return the distance between two (x,y) points or two rectangles.

  $dist = $sm->distance( $rect1, $rect2 );
  $dist = $sm->distance( [0,0], [3,4] );	# returns 5

Calculate the distance between the two arguments, which should be
references to arrays with at least two elements. Only the first two
elements will be used, so you may pass refereces to two arrays with
four elements that represent rectangles. This method may be used to
find how far away the nearest available location is from a desired
rectangle placement location.

  $s = $sm->nearest($r);
  $d = $sm->distance($r,$s);
  print "nearest available location is $d units away\n";
	
=cut

sub distance
{
  my( $self, $r1, $r2 ) = @_;
  unless ( $r2 ) {
    carp("Please pass two arguments to distance method");
    return;
  }
  my $x_delta = ( $r1->[0] - $r2->[0] );
  my $y_delta = ( $r1->[1] - $r2->[1] );
  return sqrt( ($x_delta * $x_delta) + ($y_delta * $y_delta) );
}

=head2 dump

  $sm->dump()

Print out the current set of free-space rectangles to standard output. 
The area of each rectangle is also printed. 

=cut

sub dump
{
  my $self = shift;
  print "Current Free Set ", scalar @{$self->{free}}, " Rectangles:\n";
  foreach my $rec ( 
    sort { 
      if( ${$a}[0] == ${$b}[0] ) { 
        return ${$a}[1] <=> ${$b}[1];
      }else{
        return ${$a}[0] <=> ${$b}[0];
      }
    } @{$self->{free}} ) {
    my $s = "[ @$rec ]";
    my $area = ( $$rec[2] - $$rec[0] )*( $$rec[3] - $$rec[1] );
    printf "  %8d  %s\n", $area, $s;
  }
  print "\n";
}

################################################################################

# internal functions

#	_normalize
#
#	Exchange left<->right and top<->bottom if not in order
#
sub _normalize
{
  my( $self, $rec ) = @_;
  return unless $rec;
  for my $i ( 0 .. 1 ) {
    if( $$rec[$i] > $$rec[$opposite[$i]] ) {
      ( $$rec[$i], $$rec[$opposite[$i]] ) = 
      ( $$rec[$opposite[$i]], $$rec[$i] );
    }
  }
}

#	_normalized
#
#	Return list of boundaries of normalized rectangle
#
sub _normalized
{
  my( $self, $rec ) = @_;
  return unless $rec;
  my( $left, $bottom, $right, $top ) = @$rec;
  if( $left > $right ) {
    ( $left, $right ) = ( $right, $left );
  }
  if( $bottom > $top ) {
    ( $bottom, $top ) = ( $top, $bottom );
  }
  return ( $left, $bottom, $right, $top );
}

=head1 ACKNOWLEDGMENTS

The algorithm used is based on that described by Bernard and Jacquenet
in "Free space modeling for placing rectangles without overlap"
which appeared in the Journal of Universal Computer Science, vol. 3,
no. 6, 1997. See http://www.jucs.org/jucs_3_6/free_space_modeling_for

The term "space manager" was used by Bell and Feiner in their paper
"Dynamic Space Management for User Interfaces",
Proc. UIST '00, San Diego, CA, November 5-8 2000. pp. 239-248.

=head1 LIMITATIONS

The algorithm used is first-come-first-served and makes no attempt at
optimization such as minimum displacements. The first rectangle placed
will occupy its desired location, while others may have to be moved,
farther and farther as more are placed.

There is no method for removing rectangles and restoring the space
they occupied. Doing so is not trivial and remains the goal of a
later update to this module, if there turns out to be a demand for
such a feature. See the Bell and Feiner paper cited above for details
on how this could be done.

This module does in theory handle the placement of overlapping 
rectangles. That is you can place a rectangle that overlaps a
rectangle that was already added and was, therefore, not
returned by a call to the nearest method. The module should
reduce the free space correctly in this case. However, this 
feature has not been thoroughly tested and there may still be
bugs. It is safest to add only rectangles that have been returned
from the nearest method.

=head1 BUGS

None known at this time.

=head1 SUPPORT

Please e-mail the author if any bugs are found.

=head1 AUTHOR

	Jim Gibson
	CPAN ID: JGIBSON
	
	Jim@Gibson.org
	jim.gibson.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1;
