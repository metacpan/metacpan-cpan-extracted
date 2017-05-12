# Copyright 2011, 2012 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

package Math::NumSeq::SquareFreeKernel;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 88;
use Math::NumSeq 7; # v.7 for _is_infinite()
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant description => Math::NumSeq::__('The square-free kernel of i, ie. divide out any factor k^2.');
use constant characteristic_non_decreasing => 0;
use constant characteristic_integer => 1;
use constant characteristic_smaller => 1;
use constant values_min => 1;
use constant i_start => 1;

use constant parameter_info_array =>
  [
   { name    => 'power',
     type    => 'integer',
     default => '2',
     minimum => 2,
     width   => 2,
     # description => Math::NumSeq::__(''),
   },
  ];

# A062378
my @oeis_anum = (undef,
                 undef,
                 'A007947',
                 'A007948',  # largest cube-free dividing n
                 'A058035',  # 4
                 # OEIS-Catalogue: A007947
                 # # OEIS-Catalogue: A050985 power=3
                 # # OEIS-Catalogue: A053165 power=4
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'power'}];
}

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  _restart_sieve ($self, 20);
}
sub _restart_sieve {
  my ($self, $hi) = @_;
  ### _restart_sieve() ...
  $self->{'hi'} = $hi;
  my $array = $self->{'array'} = [];
  $#$array = $hi;
  $array->[1] = 1;
}

sub next {
  my ($self) = @_;

  my $i = my $target = $self->{'i'}++;
  if ($i > $self->{'hi'}) {
    _restart_sieve ($self, ($self->{'hi'} *= 2));
    $i = 2;
  }

  my $hi = $self->{'hi'};
  my $aref = $self->{'array'};

  my $ret;
  for ( ; $i <= $target; $i++) {
    $ret = $aref->[$i];
    if (! defined $ret) {
      ### prime: $i

      # composites marked
      for (my $j = 2*$i; $j <= $hi; $j += $i) {
        ### composite: $j
        $aref->[$j] ||= $j;
      }

      # square(etc) factors divided out
      my $pow = $i ** $self->{'power'};
      for (my $j = $pow; $j <= $hi; $j += $pow) {
        ### divide: "j=$j value $aref->[$j] by $i"
        $aref->[$j] /= $i;
      }
      for (my $step = $pow*$pow; $step <= $hi; $step *= $pow) {
        for (my $j = $step; $j <= $hi; $j += $step) {
          $aref->[$j] /= $pow;
        }
      }
    }
  }
  return ($target, $ret||$target);
}

sub ith {
  my ($self, $i) = @_;
  ### SquareFreeKernel ith(): $i

  if (abs($i) > 0xFFFF_FFFF) {
    return undef;
  }
  if (_is_infinite($i)) {
    return $i;
  }
  if (abs($i) < 4) {
    return $i;
  }

  my $power = $self->{'power'};
  {
    my $pow = 2 ** $power;
    if (($i % $pow) == 0) {
      $i /= 2;
      while (($i % $pow) == 0) {
        $i /= $pow;
      }
    }
  }

  for (my $p = 3; ; $p += 2) {
    my $pow = $p ** $power;
    last if $pow > abs($i);
    if (($i % $pow) == 0) {
      $i /= $p;
      while (($i % $pow) == 0) {
        $i /= $pow;
      }
    }
  }
  return $i;
}

sub pred {
  my ($self, $value) = @_;
  ### SquareFreeKernel pred(): $value

  if ($value != int($value) || _is_infinite($value)) {
    return 0;
  }
  if ($value < 0 || $value > 0xFFFF_FFFF) {
    return undef;
  }

  my $power = $self->{'power'};

  if (($value % 2) == 0) {
    $value /= 2;
    my $count = $power;
    while (($value % 2) == 0) {
      if (--$count <= 0) {
        return 0;  # power factor
      }
      $value /= 2;
    }
  }

  my $limit = $value ** (1/$power) + 1;
  my $p = 3;
  while ($p <= $limit) {
    if (($value % $p) == 0) {
      $value /= $p;
      my $count = $power;
      while (($value % $p) == 0) {
        if (--$count <= 0) {
          return 0;  # power factor
        }
        $value /= $p;
      }
      $limit = $value ** (1/$power) + 1;
      ### factor: "$p new limit $limit"
    }
    $p += 2;
  }
  return 1;
}

1;
__END__

=for stopwords Ryde Math-NumSeq ie

=head1 NAME

Math::NumSeq::SquareFreeKernel -- divide out any square factor

=head1 SYNOPSIS

 use Math::NumSeq::SquareFreeKernel;
 my $seq = Math::NumSeq::SquareFreeKernel->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The sequence of i with any square factor divided out,

    1, 2, 3, 1, 5, 6, 7, 2, 1, 10, 11, 3, ...

For example at i=12 the value is 3 because the square 4 is divided out.

=head1 FUNCTIONS

=over 4

=item C<$seq = Math::NumSeq::SquareFreeKernel-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$i> with any square factor divided out.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, ie. it has no square
factor.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::MobiusFunction>

=cut
