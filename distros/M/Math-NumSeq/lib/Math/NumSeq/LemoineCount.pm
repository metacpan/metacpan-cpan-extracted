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

package Math::NumSeq::LemoineCount;
use 5.004;
use strict;
use List::Util 'max';

use vars '$VERSION', '@ISA';
$VERSION = 73;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Primes;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Lemoine Count');
use constant description => Math::NumSeq::__('The number of ways i can be represented as P+2*Q for primes P and Q.');
use constant default_i_start => 1;
use constant values_min => 0;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;

use constant parameter_info_array =>
  [
   {
    name        => 'on_values',
    share_key   => 'on_values_odd',
    type        => 'enum',
    default     => 'all',
    choices     => ['all','odd'],
    choices_display => [Math::NumSeq::__('All'),
                        Math::NumSeq::__('Odd')],
    description => Math::NumSeq::__('The values to act on, either all integers of just the odd integers.'),
   },
  ];

#-----------------------------------------------------------------------------
# "one_as_prime" secret undocumented parameter ...
# some sort of odd i only option too maybe ...
#
# A046925 ways 2n+1, including 1 as a prime
# A046927 ways 2n+1, not including 1 as a prime
# A194831 records of A046927
# A194830 positions of records

my %oeis_anum = (all => [ 'A046924',  # ways n, including 1 as a prime
                          'A046926',  # ways n, not including 1 as a prime
                        ],
                 odd => [ 'A046925',  # ways n, including 1 as a prime
                          'A046927',  # ways n, not including 1 as a prime
                        ],
                );
# OEIS-Catalogue: A046926
# OEIS-Catalogue: A046924 one_as_prime=1
# OEIS-Catalogue: A046927 on_values=odd    # starting n=0 for odd=1
# OEIS-Catalogue: A046925 on_values=odd one_as_prime=1
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'on_values'}}->[!$self->{'one_as_prime'}];
}

#-----------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  ### LemoineCount rewind() ...
  $self->{'i_start'} = ($self->{'on_values'} eq 'odd' ? 0 : 1);
  $self->{'i'} = $self->i_start;
  $self->{'a'} = 1;
  $self->{'array'} = [];
  $self->{'size'} = 500;
}

sub next {
  my ($self) = @_;
  ### next(): "i=$self->{'i'}"

  for (;;) {
    unless (@{$self->{'array'}}) {
      $self->{'size'} = int (1.08 * $self->{'size'});

      my $lo = $self->{'a'};
      my $hi = $lo + $self->{'size'};
      $self->{'next_lo'} = $hi+1;
      ### range: "lo=$lo to hi=$hi"

      my @array;
      $array[$hi-$lo] = 0; # array size
      $self->{'array'} = \@array;

      my @primes = (($self->{'one_as_prime'} ? (1) : ()),
                    Math::NumSeq::Primes::_primes_list (0, $hi));
      {
        my $qamax = $#primes;
        foreach my $pa (0 .. $#primes-1) {
          foreach my $qa (reverse $pa .. $qamax) {
            my $sum = $primes[$pa] + 2*$primes[$qa];
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
      {
        my $qamax = $#primes;
        foreach my $pa (0 .. $#primes-1) {
          foreach my $qa (reverse $pa+1 .. $qamax) {
            my $sum = 2*$primes[$pa] + $primes[$qa];
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
    }

    my $a = $self->{'a'}++;
    my $value = shift @{$self->{'array'}} || 0;
    if ($self->{'on_values'} eq 'odd' && !($a&1)) {
      next;
    }
    return ($self->{'i'}++, $value);
  }
}

sub ith {
  my ($self, $i) = @_;
  ### ith(): $i

  if ($self->{'on_values'} eq 'odd') {
    $i = 2*$i+1;
  }
  if ($i < 3) {
    return 0;
  }
  unless ($i >= 0 && $i <= 0xFF_FFFF) {
    return undef;
  }
  $i = "$i"; # numize any Math::BigInt for speed

  my $count = 0;
  my @primes = (($self->{'one_as_prime'} ? (1) : ()),
                Math::NumSeq::Primes::_primes_list (0, $i-1));
  ### @primes
  {
    my $pa = 0;
    my $qa = $#primes;
    while ($pa <= $qa) {
      my $sum = $primes[$pa] + 2*$primes[$qa];
      if ($sum <= $i) {
        ### at: "p=$primes[$pa] q=$primes[$qa]  count ".($sum == $i)
        $count += ($sum == $i);
        $pa++;
      } else {
        $qa--;
      }
    }
  }
  {
    my $pa = 0;
    my $qa = $#primes;
    while ($pa < $qa) {
      my $sum = 2*$primes[$pa] + $primes[$qa];
      if ($sum <= $i) {
        ### at: "p=$primes[$pa] q=$primes[$qa]  count ".($sum == $i)
        $count += ($sum == $i);
        $pa++;
      } else {
        $qa--;
      }
    }
  }
  return $count;
}

1;
__END__

=for stopwords Ryde Math-NumSeq Lemoine ie

=head1 NAME

Math::NumSeq::LemoineCount -- number of representations as P+2*Q for primes P,Q

=head1 SYNOPSIS

 use Math::NumSeq::LemoineCount;
 my $seq = Math::NumSeq::LemoineCount->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is a count of how many ways i can be represented as P+2*Q for primes
P,Q, starting from i=1.

    0, 0, 0, 0, 0, 1, 1, 1, 2, 0, 2, 1, 2, 0, 2, 1, 4, 0, ...
    starting i=1

For example i=6 can only be written 2+2*2 so just 1 way.  But i=9 is 3+2*3=9
and 5+2*2=9 so 2 ways.

=head2 Odd Numbers

Option C<on_values =E<gt> 'odd'> gives the count on just the odd numbers,
starting i=0 for number of ways "1" can be expressed (none),

    0, 0, 0, 1, 2, 2, 2, 2, 4, 2, 3, 3, 3, 4, 4, 2, 5, 3, 4, ...
    starting i=0

Lemoine conjectured circa 1894 that all odd i E<gt>= 7 can be represented as
P+2*Q, which would be a count here always E<gt>=1.

=head2 Even Numbers

Even numbers i are not particularly interesting.  An even number must have P
even, ie. P=2, so i=2+2*Q for count

    count(even i) = 1 if i/2-1 is prime
                  = 0 if not

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::LemoineCount-E<gt>new ()>

=item C<$seq = Math::NumSeq::LemoineCount-E<gt>new (on_values =E<gt> 'odd')>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the sequence value at C<$i>, being the number of ways C<$i> can be
represented as P+2*Q for primes P,Q. or with the C<on_values=E<gt>'odd'>
option the number of ways for C<2*$i+1>.

This requires checking all primes up to C<$i> or C<2*$i+1> and the current
code has a hard limit of 2**24 in the interests of not going into a
near-infinite loop.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>,
L<Math::NumSeq::GoldbachCount>

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
