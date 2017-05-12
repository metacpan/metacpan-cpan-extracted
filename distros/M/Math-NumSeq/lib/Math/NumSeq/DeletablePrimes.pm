# Copyright 2012, 2013, 2014 Kevin Ryde

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


# http://mathworld.wolfram.com/DeletablePrime.html
#


package Math::NumSeq::DeletablePrimes;
use 5.004;
use strict;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099

use vars '$VERSION', '@ISA';
$VERSION = 72;

use Math::NumSeq;
use Math::NumSeq::Primes;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Deletable Primes');
use constant description => Math::NumSeq::__('Deletable primes, being primes where deleting a digit gives another prime from which in turn a digit can be deleted, etc.');
use constant i_start => 1;
use constant characteristic_increasing => 1;
use constant values_min => 2;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter


#------------------------------------------------------------------------------

# cf A080603 deleting a digit leaves a prime
#    A179336 primes containing at least one prime digit
#              a superset of the deletables
#
# http://mathworld.wolfram.com/TruncatablePrime.html
# A024770 left truncatable primes
# A024785 left truncatable primes, no zero digits
# A077390 left-and-right truncatable primes
# A137812 left or right truncatable primes
# 	 finite 149677 elements to 8939662423123592347173339993799
#
my @oeis_anum;

$oeis_anum[2] = 'A096246';
$oeis_anum[10] = 'A080608';
# OEIS-Catalogue: A096246 radix=2
# OEIS-Catalogue: A080608

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------


sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  my $primes_seq = $self->{'primes_seq'} = Math::NumSeq::Primes->new;
}

sub next {
  my ($self) = @_;
  my $primes_seq = $self->{'primes_seq'};
  for (;;) {
    (undef, my $prime) = $primes_seq->next
      or return;
    if (_prime_is_deletable($self,$prime)) {
      return ($self->{'i'}++, $prime);
    }
  }
}

sub pred {
  my ($self, $value) = @_;
  ### pred(): $value
  return ($self->Math::NumSeq::Primes::pred($value)
          && _prime_is_deletable($self,$value));
}

sub _prime_is_deletable {
  my ($self, @pending) = @_;

  my $radix = $self->{'radix'};
  my $target = ($radix == 2 ? 4 : $radix);

  while (@pending) {
    ### pending: join(', ',map{sprintf "%b", $_}@pending)

    my $value = pop @pending;
    next unless is_prime($value);
    if ($value < $target) {
      ### reached single digit, or 2,3 for binary ...
      return 1;
    }

    my $prev = -1;
    if ($radix == 10) {
      foreach my $i (($value =~ /^.(0+)/ ? length($1) : 0)
                     ..
                     length($value)-1) {
        my $digit = substr($value,$i,1);
        next if $digit eq $prev;
        $prev = $digit;
        push @pending, substr($value,0,$i) . substr($value,$i+1);
      }
    } else {

      for (my $pow = 1; $value > $pow; $pow *= $radix) {
        my $low = $value % $pow;
        my $high = int($value/$pow);

        my $digit = $high % $radix; # being deleted
        last if $high < $radix && $prev == 0; # don't delete high,0,...
        next if $digit eq $prev;
        $prev = $digit;


        push @pending, int($high/$radix) * $pow + $low;
      }
    }
  }
  return 0;
}

1;
__END__

=for stopwords Ryde Math-NumSeq ie deletable Radix radix

=head1 NAME

Math::NumSeq::DeletablePrimes -- primes deleting a digit repeatedly

=head1 SYNOPSIS

 use Math::NumSeq::DeletablePrimes;
 my $seq = Math::NumSeq::DeletablePrimes->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The deletable primes, being primes which can have a digit removed to give
another prime which in turn is deletable.

    2, 3, 5, 7, 13, 17, 23, 29, 31, 37, 43, ...
    starting i=0

For example 367 is a deletable prime because it's possible to delete the 6
giving prime 37 then from that delete the 3 giving prime 7.

There can be more than one chain of deleted digits, as for example 367
instead delete 3 to 67 then to 7.  Since the chain ends with single digit
prime 2, 3, 5 or 7, all values have at least one such digit.

Leading zeros are not allowed, so the high digit cannot be deleted if it's
followed by a zero.  For example 2003 is not a deletable prime.  Deleting
the 2 to give 003 is not allowed (though it would be a prime), and other
deletes to 203 or 200 are not primes.

=head2 Radix

The optional C<radix> parameter selects a base other than decimal.  In
binary C<radix=E<gt>2> primes 2 and 3 which are 10 and 11 are reckoned as
endpoints, since there are no single-digit primes.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DeletablePrimes-E<gt>new ()>

=item C<$seq = Math::NumSeq::DeletablePrimes-E<gt>new (radix =E<gt> $integer)>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a deletable prime, in the selected radix.

In the current code a hard limit of 2**32 is placed on the C<$value> to be
checked, in the interests of not going into a near-infinite loop.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>,
L<Math::NumSeq::SophieGermainPrimes>

=cut
