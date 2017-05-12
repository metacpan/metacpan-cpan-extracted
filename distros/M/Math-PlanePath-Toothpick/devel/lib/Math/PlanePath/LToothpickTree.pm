# Copyright 2012, 2013, 2014, 2015 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.


# math-image --wx --path=LToothpickTree --values=LinesTree --scale=10 --figure=toothpick_L

# A172310
# L-toothpick A172310 A172311 A172312 A172313


package Math::PlanePath::LToothpickTree;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 18;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;

use constant parameter_info_array =>
  [ { name      => 'start',
      share_key => 'start_upstarplus',
      display   => 'Start',
      type      => 'enum',
      default   => 'right',
      choices   => ['up','star','plus'],
    },
  ];

my @dir8_to_dx = (1,1,0,-1, -1,-1,0,1);
my @dir8_to_dy = (0,1,1,1,  0,-1,-1,-1);

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'horiz'} = 0;
  my $start = ($self->{'start'} ||= 'up');
  $self->{'rotate_list'} = [ -1, 1 ];

  my @initial_dir;
  if ($start eq 'up') {
    @initial_dir = (2);
  } elsif ($start eq 'star') {
    @initial_dir = (2, 6);
  } elsif ($start eq 'plus') {
    @initial_dir = (1, 5);
  } else {
    croak "Unrecognised start: ",$start;
  }

  foreach my $dir (@initial_dir) {
    $self->{'edges'}->{"0,0,$dir"} = 1;  # centre
    $self->{'edges'}->{_xyd_opposite(0,0,$dir)} = 1;
    foreach my $rotate (@{$self->{'rotate_list'}}) {
      my $dir = ($dir + $rotate) & 7;
      my $ox = $dir8_to_dx[$dir];
      my $oy = $dir8_to_dy[$dir];
      push @{$self->{'endpoints_x'}}, $ox;
      push @{$self->{'endpoints_y'}}, $oy;
      push @{$self->{'endpoints_dir'}}, $dir;
      $self->{'endpoints_count'}->{"$ox,$oy"}++;

      $self->{'edges'}->{"0,0,$dir"} = 1;
      $self->{'edges'}->{_xyd_opposite(0,0,$dir)} = 1;
      ### opposite: _xyd_opposite(0,0,$dir)
      if ($dir & 1) {
        ### cross1: _xyd_cross1(0,0,$dir)
        ### cross2: _xyd_cross2(0,0,$dir)
        $self->{'edges'}->{_xyd_cross1(0,0,$dir)} = 1;
        $self->{'edges'}->{_xyd_cross2(0,0,$dir)} = 1;
      }
    }
  }
  ### $self

  $self->{'xy_to_n'} = { '0,0' => 0 };
  $self->{'n_to_x'} = [ 0 ];
  $self->{'n_to_y'} = [ 0 ];
  $self->{'depth_to_n'} = [ 0 ];
  $self->{'depth'} = 0;
  return $self;
}


sub _extend {
  my ($self) = @_;
  ### _extend() ...

  my $edges = $self->{'edges'};
  # foreach my $edge (keys %$edges) {
  #   my ($x,$y,$dir) = split /,/, $edge;
  #   my $ox = $x + $dir8_to_dx[$dir];
  #   my $oy = $y + $dir8_to_dy[$dir];
  #   my $odir = ($dir + 4) & 7;
  #   my $okey = "$ox,$oy,$odir";
  #   exists $edges->{$okey} or die "Oops, missing $okey opposite of $edge";;
  # }

  my $xy_to_n = $self->{'xy_to_n'};
  my $endpoints_x = $self->{'endpoints_x'};
  my $endpoints_y = $self->{'endpoints_y'};
  my $endpoints_dir = $self->{'endpoints_dir'};
  my $endpoints_count = $self->{'endpoints_count'};

  my @no_extend;

  # never extend if would overlap existing edges,
  # or if multiple ends meeting
  for (my $i = 0; $i <= $#$endpoints_x; $i++) {
    my $x = $endpoints_x->[$i];
    my $y = $endpoints_y->[$i];
    my $dir = $endpoints_dir->[$i];
    ### endpoint check never: "$x,$y,$dir"

    if ($endpoints_count->{"$x,$y"} > 1) {
      # undef $endpoints_x->[$i];
      $no_extend[$i] = 1;
      next;
    }

    foreach my $rotate (@{$self->{'rotate_list'}}) {
      my $dir = ($dir + $rotate) & 7;
      ### check existing edge: "$x,$y,$dir"
      if (exists $edges->{"$x,$y,$dir"}) {
        ### exclude due to existing edge ...
        # undef $endpoints_x->[$i];
        $no_extend[$i] = 1;
      }
    }
  }

  # find new edges which would be traversed
  my %new_edge;
  foreach my $i (0 .. $#$endpoints_x) {
    my $x = $endpoints_x->[$i];
    next if ! defined $x;
    my $y = $endpoints_y->[$i];
    my $dir = $endpoints_dir->[$i];
    $new_edge{"$x,$y,$dir"}++;  # centre
    $new_edge{_xyd_opposite($x,$y,$dir)}++;
    foreach my $rotate (@{$self->{'rotate_list'}}) {
      my $dir = ($dir + $rotate) & 7;
      $new_edge{"$x,$y,$dir"}++;
      $new_edge{_xyd_opposite($x,$y,$dir)}++;
      if ($dir & 1) {
        $new_edge{_xyd_cross1($x,$y,$dir)}++;
        $new_edge{_xyd_cross2($x,$y,$dir)}++;
      }
    }
  }

  # no extend if duplicate new edges, but the endpoint remains a candidate
  # for later rounds
  foreach my $i (0 .. $#$endpoints_x) {
    my $x = $endpoints_x->[$i];
    next if ! defined $x;
    my $y = $endpoints_y->[$i];
    my $dir = $endpoints_dir->[$i];
    foreach my $rotate (@{$self->{'rotate_list'}}) {
      my $dir = ($dir + $rotate) & 7;
      my $key = "$x,$y,$dir";
      if ($new_edge{$key} > 1) {
        $no_extend[$i] = 1;
      }
    }
  }

  my @new_endpoints_x = ();
  my @new_endpoints_y = ();
  my @new_endpoints_dir = ();

  my $n_to_x = $self->{'n_to_x'};
  my $n_to_y = $self->{'n_to_y'};
  my $depth_to_n = $self->{'depth_to_n'};
  my $depth = scalar(@$depth_to_n);

  push @{$self->{'depth_to_n'}}, scalar(@$n_to_x); # next N which will be added

  ### $depth
  ### new depth_to_n: $self->{'depth_to_n'}

  # extend these endpoints now
  foreach my $i (0 .. $#$endpoints_x) {
    my $x = $endpoints_x->[$i];
    next if ! defined $x;
    my $y = $endpoints_y->[$i];
    my $dir = $endpoints_dir->[$i];
    ### consider extend endpoint: "xy=$x,$y,dir=$dir"

    if ($no_extend[$i]) {
      ### no extend at this depth, but maybe later ...
      push @new_endpoints_x, $x;
      push @new_endpoints_y, $y;
      push @new_endpoints_dir, $dir;
      next;
    }

    ### store: "$x,$y N=".scalar(@$n_to_x)
    $xy_to_n->{"$x,$y"} = scalar(@$n_to_x);
    push @$n_to_x, $x;
    push @$n_to_y, $y;

    $edges->{"$x,$y,$dir"} = 1;  # centre
    $self->{'edges'}->{_xyd_opposite($x,$y,$dir)} = 1;

    foreach my $rotate (@{$self->{'rotate_list'}}) {
      my $dir = ($dir + $rotate) & 7;
      $edges->{"$x,$y,$dir"} = 1;
      ### store edge: "$x,$y,$dir"
      if ($dir & 1) {
        $edges->{_xyd_cross1($x,$y,$dir)} = 1;
        $edges->{_xyd_cross2($x,$y,$dir)} = 1;
        ### store cross1: _xyd_cross1($x,$y,$dir)
        ### store cross2: _xyd_cross2($x,$y,$dir)
      }
      my $ox = $x + $dir8_to_dx[$dir];
      my $oy = $y + $dir8_to_dy[$dir];
      my $odir = ($dir + 4) & 7;  # opposite direction
      $edges->{"$ox,$oy,$odir"} = 1;
      ### store opposite edge: "$ox,$oy,$odir"
      push @new_endpoints_x, $ox;
      push @new_endpoints_y, $oy;
      push @new_endpoints_dir, $dir;
      $endpoints_count->{"$ox,$oy"}++;
    }
  }

  if ($self->{'depth_to_n'}->[-1] == scalar(@$n_to_x)) {
    ### $endpoints_x
    die "Oops, no points added";
  }

  # print "$depth added ",scalar(@$n_to_x) - $self->{'depth_to_n'}->[-1],
  #   " endpoints now ",scalar(@new_endpoints_x),"\n";

  $self->{'endpoints_x'} = \@new_endpoints_x;
  $self->{'endpoints_y'} = \@new_endpoints_y;
  $self->{'endpoints_dir'} = \@new_endpoints_dir;
  $self->{'depth'}++;
}

sub _xyd_opposite {
  my ($x,$y,$dir) = @_;
  $x += $dir8_to_dx[$dir];
  $y += $dir8_to_dy[$dir];
  $dir = ($dir + 4) & 7;  # opposite direction
  return "$x,$y,$dir";
}
sub _xyd_cross1 {
  my ($x,$y,$dir) = @_;
  $dir = ($dir - 1) & 7;   # right -1
  $x += $dir8_to_dx[$dir];
  $y += $dir8_to_dy[$dir];
  $dir = ($dir + 3) & 7;  # left +3
  return "$x,$y,$dir";
}
sub _xyd_cross2 {
  my ($x,$y,$dir) = @_;
  $dir = ($dir + 1) & 7;   # right -1
  $x += $dir8_to_dx[$dir];
  $y += $dir8_to_dy[$dir];
  $dir = ($dir - 3) & 7;  # left +3
  return "$x,$y,$dir";
}

my $stop = 725000;
sub n_to_xy {
  my ($self, $n) = @_;
  ### LToothpickTree n_to_xy(): $n

  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  if ($n > $stop) {
    return;
  }
  {
    my $int = int($n);
    ### $int
    ### $n
    if ($n != $int) {
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $frac = $n - $int;  # inherit possible BigFloat
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;       # BigFloat int() gives BigInt, use that
  }

  while ($#{$self->{'n_to_x'}} < $n) {
    _extend($self);
  }

  ### x: $self->{'n_to_x'}->[$n]
  ### y: $self->{'n_to_y'}->[$n]
  return ($self->{'n_to_x'}->[$n],
          $self->{'n_to_y'}->[$n]);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### LToothpickTree xy_to_n(): "$x, $y"
  #  ### xy_to_n hash: $self->{'xy_to_n'}

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  my $depth = 2 * (abs($x)+abs($y));
  if (is_infinite($depth)) {
    return ($depth,$depth);
  }

  for (;;) {
    my $n = $self->{'xy_to_n'}->{"$x,$y"};
    if (defined $n) {
      ### return N: $n
      return $n;
    }
    ### $depth
    if ($self->{'depth'} <= $depth) {
      _extend($self);
    } else {
      return undef;
    }
  }
}

# T(depth) = 4 * T(depth-1) + 2
# T(depth) = 2 * (4^depth - 1) / 3
# total = T(depth) + 2
# N = (4^depth - 1)*2/3
# 4^depth - 1 = 3*N/2
# 4^depth = 3*N/2 + 1
#
# len=2^depth
# total = (len*len-1)*2/3 + 2

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### LToothpickTree rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  my $depth = 4 * max(1,
                      abs($x1),
                      abs($x2),
                      abs($y1),
                      abs($y2));
  return (0, $depth*$depth);
}

sub tree_depth_to_n {
  my ($self, $depth) = @_;
  my $depth_to_n = $self->{'depth_to_n'};
  while ($#$depth_to_n <= $depth) {
    _extend($self);
  }
  return $depth_to_n->[$depth];
}
sub tree_n_to_depth {
  my ($self, $n) = @_;

  if ($n < 0) {
    return undef;
  }
  if (is_infinite($n)) {
    return $n;
  }
  my $depth_to_n = $self->{'depth_to_n'};
  for (my $depth = 1; ; $depth++) {
    while ($depth > $#$depth_to_n) {
      _extend($self);
    }
    if ($n < $depth_to_n->[$depth]) {
      return $depth-1;
    }
  }
}

sub tree_n_children {
  my ($self, $n) = @_;
  ### tree_n_children(): $n

  my ($x,$y) = $self->n_to_xy($n)
    or return;
  ### $x
  ### $y

  my @n = map { $self->xy_to_n($x+$dir8_to_dx[$_],$y+$dir8_to_dy[$_]) } 0 .. 7;
  my $want_depth = $self->tree_n_to_depth($n) + 1;

  ### $want_depth
  ### tree_n_children candidates: @n
  # ### depths: map {defined $_ && $n_to_depth->[$_]} @n

  @n = sort { $a<=>$b }
    grep { defined $_ && $self->tree_n_to_depth($_) == $want_depth }
      @n;
  ### found children: @n
  return @n;
}
sub tree_n_parent {
  my ($self, $n) = @_;

  if ($n < 1) {
    return undef;
  }
  $n = int($n);

  my ($x,$y) = $self->n_to_xy($n)
    or return undef;
  my $want_depth = $self->tree_n_to_depth($n) - 1;
  ### $want_depth
  ### assert: $want_depth >= 0

  foreach my $dir8 (0 .. 7) {
    if (defined (my $parent_n = $self->xy_to_n($x + $dir8_to_dx[$dir8],
                                               $y + $dir8_to_dy[$dir8]))) {
      ### $parent_n
      if ($self->tree_n_to_depth($parent_n) == $want_depth) {
        ### found parent: "dir8=$dir8 parent_n=$parent_n from n=$n"
        return $parent_n;
      }
    }
  }
  # die "Oops, parent of n=$n not found";
  return undef;
}

1;
__END__

=for stopwords eg Ryde Math-PlanePath-Toothpick Ulam Warburton Nstart Nend

=head1 NAME

Math::PlanePath::LToothpickTree -- toothpick sequence

=head1 SYNOPSIS

 use Math::PlanePath::LToothpickTree;
 my $path = Math::PlanePath::LToothpickTree->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

I<In progress ...>

This is the "toothpick" sequence expanding through the plane by
non-overlapping line segments (toothpicks).

=cut

# math-image --path=LToothpickTree --output=numbers --all --size=65x11

=pod

           5

           4

           3

           2

           1

      <- Y=0

          -1

          -2

          -3

          -4

          -5
                       ^
      -4   -3 -2  -1  X=0  1   2   3   4

=cut

# Each X,Y point is the centre of a three-pronged toothpick.  The toothpick is
# vertical on "even" points X+Y==0 mod 2, or horizontal on "odd" points X+Y==1
# mod 2.
#
# Points are numbered by each growth depth at the endpoints, and
# anti-clockwise around when there's a new point at both ends of an existing
# toothpick.

=pod




               \   / \   /
                \ /   \ /
                 4     3----
  \   /           \   /    /
   \ /             \ /    /
    1----           1----2----
                          \
                           \



        \   /       \   /
         \ /         \ /
     -----8           7----
     \     \   / \   /
      \     \ /   \ /
  -----9-----4     3----
      /       \   /    /    /
     /         \ /    /    /
                1----2----6----
                      \    \
                       \    \
                        5----
                       / \
                      /   \


=cut

# The start is N=1 and points N=2 and N=3 are added to the two ends of that
# toothpick.  Then points N=4,5,6,7 are added at those four ends.
#
# For points N=4,5,6,7 a new toothpick is only added at each far ends, not the
# "inner" positions X=1,Y=0 and X=-1,Y=0.  This is because those points are
# the ends of two toothpicks and would overlap.  X=1,Y=0 is the end of
# toothpicks N=4 and N=7, and X=-1,Y=0 the ends of N=5,N=6.  The rule is that
# when two ends meet like that nothing is added at that point.  The end of a
# toothpick is allowed to touch an existing toothpick.  The first time this
# happens is N=16.  Its left end touches N=4.
#
# The stair-step X=Y,X=Y-1 diagonal N=2,4,8,12,17,25,36,44,49 etc and similar
# in the other quadrants extend indefinitely.  The quarters to either side of
# the diagonals are filled in a self-similar fashion.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::LToothpickTree-E<gt>new ()>

Create and return a new path object.

=back

=cut

# =head2 Tree Methods
#
# =over
#
# =item C<@n_children = $path-E<gt>tree_n_children($n)>
#
# Return the children of C<$n>, or an empty list if C<$n> has no children
# (including when C<$n E<lt> 1>, ie. before the start of the path).
#
# The children are the new toothpicks added at the ends of C<$n> in the next
# depth.  This can be none, one or two points.
#
# =cut
#
# #   For example N=8 has a single
# # child 12, N=24 has no children, or N=2 has two children 4,5.  The way points
# # are numbered means when there's two children they're consecutive N values.
#
# =item C<$num = $path-E<gt>tree_n_num_children($n)>
#
# Return the number of children of C<$n>, or return C<undef> if C<$nE<lt>1>
# (ie. before the start of the path).
#
# =item C<$n_parent = $path-E<gt>tree_n_parent($n)>
#
# Return the parent node of C<$n>, or C<undef> if C<$n E<lt>= 1> (the start of
# the path).
#
# =back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::UlamWarburton>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015 Kevin Ryde

This file is part of Math-PlanePath-Toothpick.

Math-PlanePath-Toothpick is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Math-PlanePath-Toothpick is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

=cut
