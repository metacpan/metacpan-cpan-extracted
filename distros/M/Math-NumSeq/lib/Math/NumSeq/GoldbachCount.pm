# Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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


# http://mathworld.wolfram.com/GoldbachConjecture.html


package Math::NumSeq::GoldbachCount;
use 5.004;
use strict;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099

use vars '$VERSION', '@ISA';
$VERSION = 73;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Primes;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Goldbach Count');
use constant description => Math::NumSeq::__('The number of ways i can be represented as P+Q for primes P and Q.  The Goldbach conjecture is that all even i>=4 can be represented in at least one such way.');
use constant default_i_start => 1;
use constant values_min => 0;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;

# not documented yet
use constant parameter_info_array =>
  [
   {
    name        => 'on_values',
    share_key   => 'on_values_even',
    type        => 'enum',
    default     => 'all',
    choices     => ['all','even'],
    choices_display => [Math::NumSeq::__('All'),
                        Math::NumSeq::__('Even')],
    # description => Math::NumSeq::__('...'),
   },
  ];

#------------------------------------------------------------------------------
# cf A014092 - n not P+Q, ie. count=0, starting from value=1
#    A014091 - n some P+Q, ie. count!=0
#    A067187 - n one way P+Q, ie. count=1
#    A067188 - n two ways, count=2
#    A067189 - n three ways
#    A067190 - n four ways
#    A067191 - n five ways
#    A073610 - num primes n-p where p prime, so counting two ways
#    A045917 - 2n, ordered sum
#    A185297 - sum of the p's p+q=2n
#    A185298 - sum of the q's p+q=2n
#    A002372 - count for two odd primes
#
#    A045917 - unordered 2n, start n=1 is 2
#              odd or even primes, so n=2 is 4 count 1 for 2+2=4
#    A002375 - unordered 2n, start n=1 is 2
#              odd primes, so n=2 is 4 count 1 for 2+2=4
#
my %oeis_anum = ('all'  => 'A061358', # ordered p>=q, start n=0
                 'even' => 'A045917', # unordered sum, start n=1 is 2
                 # OEIS-Catalogue: A061358 i_start=0
                 # OEIS-Catalogue: A045917 on_values=even
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'on_values'}};
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  ### GoldbachCount rewind() ...
  $self->{'i'} = $self->i_start;

  # special case initial array for even so can then exclude prime p=2 from loop
  $self->{'array'} = ($self->{'on_values'} eq 'even'
                      ? [ 0, 0, 1, 1 ]
                      : []);
  $self->{'size'} = 499;  # must be odd for 2i case
}

sub next {
  my ($self) = @_;
  ### next(): "i=$self->{'i'}, arraylen=".scalar(@{$self->{'array'}})

  unless (@{$self->{'array'}}) {
    $self->{'size'} = int(1.1 * $self->{'size'}) | 1; # must be odd

    my $lo = $self->{'i'};
    my $even_only = ($self->{'on_values'} eq 'even');
    if  ($even_only) {
      $lo *= 2;
    }
    my $hi = $lo + $self->{'size'};
    ### range: "lo=$lo to hi=$hi"
    my @array;
    $array[$hi-$lo] = 0; # array size

    my @primes = Math::NumSeq::Primes::_primes_list (0, $hi);
    if ($even_only) {
      shift @primes;  # skip P=2
    }

    {
      my $qamax = $#primes;
      foreach my $pa (0 .. $#primes-1) {
        foreach my $qa (reverse $pa .. $qamax) {
          my $sum = $primes[$pa] + $primes[$qa];
          ### at: "p=$primes[$pa] q=$primes[$qa]  sum=$sum  incr ".($sum-$lo)
          if ($sum > $hi) {
            $qamax = $qa-1;
          } elsif ($sum < $lo) {
            last;
          } else {
            $array[$sum-$lo]++;
          }
        }
      }
    }
    ### @array
    $self->{'array'} = \@array;
  }

  my $value = shift @{$self->{'array'}} || 0;
  ### $value
  if ($self->{'on_values'} eq 'even') {
    shift @{$self->{'array'}}; # skip odd
  }
  return ($self->{'i'}++, $value);
}

sub ith {
  my ($self, $i) = @_;
  ### ith(): $i

  if ($self->{'on_values'} eq 'even') {
    $i *= 2;
  }
  if ($i <= 3) {
    return 0;
  }
  unless ($i >= 0 && $i <= 0xFF_FFFF) {
    return undef;
  }
  $i = "$i"; # numize any Math::BigInt for speed

  if ($i & 1) {
    ### odd, check prime: $i-2
    return (is_prime($i-2) ? 1 : 0);  # odd only i=2+Q for prime Q
  }

  my $count = 0;
  my @primes = Math::NumSeq::Primes::_primes_list (0, $i-1);
  ### @primes

  my $pa = 0;
  my $qa = $#primes;
  while ($pa <= $qa) {
    my $sum = $primes[$pa] + $primes[$qa];
    if ($sum <= $i) {
      ### at: "p=$primes[$pa] q=$primes[$qa]  incr=".($sum == $i)
      $count += ($sum == $i);
      $pa++;
    } else {
      $qa--;
    }
  }

  ### $count
  return $count;
}

sub pred {
  my ($self, $value) = @_;
  ### HypotCount pred(): $value
  return ($value >= 0 && $value == int($value));
}

1;
__END__

=for stopwords Ryde  PlanePath Math-NumSeq Goldbach's

=head1 NAME

Math::NumSeq::GoldbachCount -- number of representations as sum of primes P+Q

=head1 SYNOPSIS

 use Math::NumSeq::GoldbachCount;
 my $seq = Math::NumSeq::GoldbachCount->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The number of ways each i can be represented as a sum of two primes P+Q,
starting from i=1,

    0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 0, 1, 1, 2, 1, 2, 0, ...
    starting i=1

For example i=4 can be represented only as 2+2 so just 1 way.  Or i=10 is
3+7 and 5+5 so 2 ways.

=head2 Even Numbers

Option C<on_values =E<gt> 'even'> gives the count on just the even numbers,
starting i=1 for number of ways "2" can be expressed (none),

    0, 1, 1, 1, 2, 1, 2, 2, 2, 2, 3, 3, 3, 2, 3, 2, 4, 4, ...
    starting i=1

Goldbach's famous conjecture is that for an even i E<gt>= 4 there's always
at least one P+Q=i, which would be a count here always E<gt>= 1.

=head2 Odd Numbers

Odd numbers i are not particularly interesting.  An odd number can only be
i=2+Prime, so the count is simply

    count(odd i) = 1  if i-2 prime
                   0  if not

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::GoldbachCount-E<gt>new ()>

=item C<$seq = Math::NumSeq::GoldbachCount-E<gt>new (on_values =E<gt> 'even')>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the sequence value at C<$i>, being the number of ways C<$i> can be
represented as a sum of primes P+Q, or with the C<on_values=E<gt>'even'>
option the number of ways for C<2*$i>.

This requires checking all primes up to C<$i> (or C<2*$i>) and the current
code has a hard limit of 2**24 in the interests of not going into a
near-infinite loop.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs as a count.  All counts 0 upwards occur so
this is simply integer C<$value E<gt>= 0>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>,
L<Math::NumSeq::LemoineCount>,
L<Math::NumSeq::PrimeFactorCount>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016 Kevin Ryde

Math-NumSeq is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

=cut
