# Copyright 2012, 2013 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# Grows too quickly to be interesting.
#
# math-image --path=FibonacciSquareSpiral --lines --scale=10
# math-image --path=FibonacciSquareSpiral --output=numbers


# #------------------------------------------------------------------------------
# # A138710 - abs(dX) but OFFSET=1
# 
# MyOEIS::compare_values
#   (anum => 'A138710',
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $n = $path->n_start; @got < $count; $n++) {
#        my ($dx,$dy) = $path->n_to_dxdy($n);
#        push @got, abs($dx);
#      }
#      return \@got;
#    });
# 
# # A138709 - abs(dY) but OFFSET=1
# MyOEIS::compare_values
#   (anum => 'A138709',
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $n = $path->n_start; @got < $count; $n++) {
#        my ($dx,$dy) = $path->n_to_dxdy($n);
#        push @got, abs($dy);
#      }
#      return \@got;
#    });


package Math::PlanePath::FibonacciSquareSpiral;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 104;
use Math::PlanePath 37;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh';

# uncomment this to run the ### lines
#use Devel::Comments;

use constant default_n_start => 1;

sub new {
  my $self = shift->SUPER::new (@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  #### SquareSpiral n_to_xy: $n

  $n = $n - $self->{'n_start'};  # starting $n==0, warn if $n==undef
  if ($n < 0) {
    #### before n_start ...
    return;
  }

  my $f0 = int($n)*0;  # inherit BigInt zero
  my $f1 = $f0 + 1;    # inherit BigInt one
  my $x = 0;
  my $y = 0;
  my $dx = 1;
  my $dy = 0;
  while ($n > $f1) {
    $n -= $f1;
    $x += $dx * $f1;
    $y += $dy * $f1;
    ($f1,$f0) = ($f1+$f0,$f1);
    ($dx,$dy) = (-$dy,$dx); # rotate +90
  }
  return ($n*$dx + $x, $n*$dy + $y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### FibonacciSquareSpiral xy_to_n() ...

  return undef;
}

sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  return ($self->{'n_start'},
          $self->{'n_start'} + max($x1,$x2,$y1,$y2)**2);
}

1;
__END__

=for stopwords eg Ryde

=head1 NAME

Math::PlanePath::FibonacciSquareSpiral -- spiral with Fibonacci number sides

=head1 SYNOPSIS

 use Math::PlanePath::FibonacciSquareSpiral;
 my $path = Math::PlanePath::FibonacciSquareSpiral->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is ...

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::FibonacciSquareSpiral-E<gt>new ()>

Create and return a new path object.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SquareSpiral>

=head1 HOME PAGE

http://user42.tuxfamily.org/math-planepath/index.html

=head1 LICENSE

Copyright 2012, 2013 Kevin Ryde

This file is part of Math-PlanePath.

Math-PlanePath is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-PlanePath is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

=cut
