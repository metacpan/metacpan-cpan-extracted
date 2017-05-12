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


# Is 4 fused SierpinskiTriangle

# A160720,A160721 diagonal adjacent and not nearer the origin
#     differs from A147562 ulam-warbuton first at depth=8

# 3 fused SierpinskiTriangle
# A160722 total cells = 3*A006046(n) - 2*n, subtracting 2 fused sides
# A160723 added cells
# http://www.polprimos.com/imagenespub/polca722.jpg

package Math::PlanePath::UlamWarburtonAway;
use 5.004;
use strict;
#use List::Util 'max','min';
*max = \&Math::PlanePath::_max;
*min = \&Math::PlanePath::_min;

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
#use Smart::Comments;


use constant n_start => 0;

sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'parts'}) {
    $self->{'parts'} = 4;
  }

  $self->{'endpoints_x'} = [ 1, -1, -1,  1 ];
  $self->{'endpoints_y'} = [ 1,  1, -1, -1 ];
  $self->{'endpoints_dir'} = [ 0, 1, 2, 3 ];
  $self->{'xy_to_n'} = { '0,0' => 0,
                         '1,1' => 1,
                         '-1,1' => 2,
                         '-1,-1' => 3,
                         '1,-1' => 4 };
  $self->{'n_to_x'} = [ 0, 1, -1, -1,  1 ];
  $self->{'n_to_y'} = [ 0, 1,  1, -1, -1 ];
  $self->{'level_to_n'} = [ 0, 1, 5 ];
  $self->{'level'} = 1;
  return $self;
}

my @dir4diag_to_dx = (1,-1,-1, 1);
my @dir4diag_to_dy = (1, 1,-1,-1);

sub _extend {
  my ($self) = @_;
  ### _extend(): $self
  my $xy_to_n = $self->{'xy_to_n'};
  my $endpoints_x   = $self->{'endpoints_x'};
  my $endpoints_y   = $self->{'endpoints_y'};
  my $endpoints_dir = $self->{'endpoints_dir'};
  my @extend_x;
  my @extend_y;
  my @extend_dir;
  my %extend;
  foreach my $i (0 .. $#$endpoints_x) {
    my $x   = $endpoints_x->[$i];
    my $y   = $endpoints_y->[$i];
    my $dir = $endpoints_dir->[$i];
    foreach my $ddir (-1, 0, 1) {
      my $new_dir = ($dir + $ddir) & 3;
      my $dx = $dir4diag_to_dx[$new_dir];
      my $dy = $dir4diag_to_dy[$new_dir];
      my $new_x = $x + $dx;
      my $new_y = $y + $dy;
      if ($new_x**2 + $new_y**2 < $x**2 + $y**2) {
        next;
      }

      my $key = "$new_x,$new_y";
      unless ($xy_to_n->{$key}) {
        $extend{$key}++;
        push @extend_x, $new_x;
        push @extend_y, $new_y;
        push @extend_dir, $new_dir;
      }
    }
  }

  @$endpoints_x = ();
  @$endpoints_y = ();
  @$endpoints_dir = ();
  foreach my $i (0 .. $#extend_x) {
    my $x = $extend_x[$i];
    my $y = $extend_y[$i];
    my $dir = $extend_dir[$i];
    my $key = "$x,$y";
    next if $extend{$key} > 1;
    push @$endpoints_x, $x;
    push @$endpoints_y, $y;
    push @$endpoints_dir, $dir;
  }
  my $n_to_x = $self->{'n_to_x'};
  my $n_to_y = $self->{'n_to_y'};
  foreach my $i (0 .. $#$endpoints_x) {
    my $x = $endpoints_x->[$i];
    my $y = $endpoints_y->[$i];
    push @$n_to_x, $x;
    push @$n_to_y, $y;
    $xy_to_n->{"$x,$y"} = $#$n_to_x;
  }
  push @{$self->{'level_to_n'}}, $#$n_to_x + 1;
  $self->{'level'}++;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### UlamWarburtonAway n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

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
  ### $self

  ### x: $self->{'n_to_x'}->[$n]
  ### y: $self->{'n_to_y'}->[$n]
  return ($self->{'n_to_x'}->[$n],
          $self->{'n_to_y'}->[$n]);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### UlamWarburtonAway xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  my ($len,$level) = round_down_pow (max(abs($x), abs($y)-1),
                                     2);
  $len *= 4;
  if (is_infinite($len)) {
    return ($len);
  }
  while ($self->{'level'} <= $len) {
    _extend($self);
  }
  return $self->{'xy_to_n'}->{"$x,$y"};
}

# T(level) = 4 * T(level-1) + 2
# T(level) = 2 * (4^level - 1) / 3
# total = T(level) + 2
# N = (4^level - 1)*2/3
# 4^level - 1 = 3*N/2
# 4^level = 3*N/2 + 1
#
# len=2^level
# total = (len*len-1)*2/3 + 2

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### UlamWarburtonAway rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  my ($len,$level) = round_down_pow (max(abs($x1),  abs($x2),
                                         abs($y1)-1,abs($y2)-1),
                                     2);
  ### $level
  ### $len
  if (is_infinite($level)) {
    return (0,$level);
  }

  $len *= 4;
  return (0, ($len*$len-1)*2/3+2);
}

# ENHANCE-ME: calculate by the bits of n, not by X,Y
sub tree_n_children {
  my ($self, $n) = @_;
  ### tree_n_children(): $n

  my ($x,$y) = $self->n_to_xy($n)
    or return; # before n_start(), no children

  my @ret;
  foreach my $c ($self->xy_to_n($x+1,$y+1),
                 $self->xy_to_n($x-1,$y+1),
                 $self->xy_to_n($x+1,$y-1),
                 $self->xy_to_n($x-1,$y-1)) {
    if (defined $c && $c > $n) {
      push @ret, $c;
    }
  }
  return sort {$a<=>$b} @ret;
}
sub tree_n_parent {
  my ($self, $n) = @_;
  $n = int($n);
  if ($n < 1) {
    return undef;
  }
  my ($x,$y) = $self->n_to_xy($n)
    or return undef;
  my $found;
  foreach my $p ($self->xy_to_n($x+1,$y+1),
                 $self->xy_to_n($x-1,$y+1),
                 $self->xy_to_n($x+1,$y-1),
                 $self->xy_to_n($x-1,$y-1)) {
    if (defined $p && (! defined $found || $p < $found)) {
      $found = $p;
    }
  }
  return $found;
}

# by tree_n_parents()
sub tree_n_to_depth {
  my ($path, $n) = @_;
  if ($n < $path->n_start) {
    return undef;
  }
  my $depth = 0;
  for (;;) {
    my $parent_n = $path->tree_n_parent($n);
    last if ! defined $parent_n;
    if ($parent_n >= $n) {
      die "Oops, tree parent $parent_n >= child $n in ", ref $path;
    }
    $n = $parent_n;
    $depth++;
  }
  return $depth;
}

# sub tree_n_to_depth {
#   my ($self, $n) = @_;
#   ### tree_n_to_depth(): "$n"
# 
#   if ($n < 0) {
#     return undef;
#   }
#   $n = int($n);
#   if ($n < 1) {
#     ### initial point ...
#     return 0;
#   }
# 
#   my $parts = $self->{'parts'};
#   my $depth_offset;
# 
#   if (is_infinite($n)) {
#     return $n;
#   }
#   my ($depth) = _n0_to_depth_and_rem($n, $self->{'parts'});
#   ### n0 depth: $depth
#   return $depth - $depth_offset;
# }

# # T(2^k+rem) = T(2^k) + T(rem) + 2T(rem-1)   rem>=1
# #          
# sub tree_depth_to_n {
#   my ($self, $depth) = @_;
#   ### tree_depth_to_n(): $depth
# 
#   if ($depth < 0) {
#     return undef;
#   }
#   $depth = int($depth);
#   if ($depth < 2) {
#     return $depth;  # 0 or 1, for any $parts
#   }
# 
#   my $parts = $self->{'parts'};
#   if ($parts == 1) {
#     $depth += 2;
#   } elsif ($parts == 2) {
#     $depth += 1;
#   }
# 
#   my ($pow,$exp) = round_down_pow ($depth, 2);
#   if (is_infinite($exp)) {
#     return $exp;
#   }
#   ### $pow
#   ### $exp
# 
#   my $zero = $depth*0;
#   my $n = $zero;
#   my @powtotal = (1);
#   {
#     my $t = 2 + $zero;
#     push @powtotal, $t;
#     foreach (1 .. $exp) {
#       $t = 4*$t + 2;
#       push @powtotal, $t;
#     }
#     ### @powtotal
#   }
# 
#   if ($depth < 1) {
#     return $zero;
#   }
# 
#   my @pending = ($depth);
#   my @mult = (1 + $zero);
# 
#   while (--$exp >= 0) {
#     last unless @pending;
# 
#     ### @pending
#     ### @mult
#     ### $exp
#     ### $pow
#     ### powtotal: $powtotal[$exp]
# 
#     my @new_pending;
#     my @new_mult;
# 
#     # if (join(',',@pending) ne join(',',reverse sort {$a<=>$b} @pending)) {
#     #   print " ",join(',',@pending),"\n";
#     # }
# 
#     foreach my $depth (@pending) {
#       my $mult = shift @mult;
#       ### assert: $depth >= 2
# 
#       if ($depth == 2) {
#         next;
#       }
#       if ($depth == 3) {
#         $n += $mult;
#         next;
#       }
# 
#       if ($depth < $pow) {
#         push @new_pending, $depth;
#         push @new_mult, $mult;
#         next;
# 
#         # Cannot stop here as @pending isn't necessarily sorted into
#         # descending order.
#         # @pending = (@new_pending, $depth, @pending);
#         # @mult = (@new_mult, $mult, @mult);
#         # $pow /= 2;
#         # print "$pow   ",join(',',@pending),"\n";
#         # next OUTER;
#       }
# 
#       my $rem = $depth - $pow;
# 
#       ### $depth
#       ### $mult
#       ### $rem
# 
#       if ($rem >= $pow) {
#         ### twice pow: $powtotal[$exp+1]
#         $n += $powtotal[$exp+1] * $mult;
#         next;
#       }
#       ### assert: $rem >= 0 && $rem < $pow
# 
#       $n += $mult * $powtotal[$exp];
# 
#       if ($rem == 0) {
#         ### rem==0, so just the powtotal ...
#         next;
#       }
# 
#       if ($rem == 1) {
#         ### rem==1 A of each part ...
#         $n += $mult;
# 
#         # } elsif ($rem < 3) {
#         #   ### rem==2 A+B+1 of each part ...
#         #   $n += 3 * $mult;
# 
#       } else {
#         # T(pow+rem) = T(pow) + T(rem) + 2T(rem-1) + 2
#         $rem += 1;
#         $n += 2*$mult;
# 
# 
#         if (@new_pending && $new_pending[-1] == $rem) {
#           # print "rem=$rem ",join(',',@new_pending),"\n";
#           $new_mult[-1] += $mult;
#         } else {
#           push @new_pending, $rem;
#           push @new_mult, $mult;
#         }
#         if ($rem -= 1) {
#           push @new_pending, $rem;
#           push @new_mult, 2*$mult;
#         }
#       }
#     }
#     @pending = @new_pending;
#     @mult = @new_mult;
#     $pow /= 2;
#   }
# 
#   ### return: $n
#   return $n * $parts + $parts-1;
# 
#   # $parts_depth_offset[$parts];
#   # my @parts_depth_offset = (undef, 0, 1, 2, 3);
# }


1;
__END__

=for stopwords eg Ryde Math-PlanePath-Toothpick OEIS

=head1 NAME

Math::PlanePath::UlamWarburtonAway -- toothpick sequence

=head1 SYNOPSIS

 use Math::PlanePath::UlamWarburtonAway;
 my $path = Math::PlanePath::UlamWarburtonAway->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

I<In progress ...>

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::UlamWarburtonAway-E<gt>new ()>

Create and return a new path object.

=back

=head2 Tree Methods

=over

=item C<@n_children = $path-E<gt>tree_n_children($n)>

Return the children of C<$n>, or an empty list if C<$n> has no children
(including when C<$n E<lt> 0>, ie. before the start of the path).

=item C<$n_parent = $path-E<gt>tree_n_parent($n)>

Return the parent node of C<$n>, or C<undef> if C<$n E<lt>= 0> (the start of
the path).

=back

=head1 OEIS

This cellular automaton is in Sloane's Online Encyclopedia of Integer
Sequences as

=over

L<http://oeis.org/A160720> (etc)

=back

    A160720   total cells at depth=n
    A160721   added cells at depth=n

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
