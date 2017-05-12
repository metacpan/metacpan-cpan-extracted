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

package Math::NumSeq::ErdosSelfridgeClass;
use 5.004;
use strict;
use Math::NumSeq::Primes;

use vars '$VERSION', '@ISA';
$VERSION = 72;

use Math::NumSeq;
@ISA = ('Math::NumSeq');

use Math::NumSeq::PrimeFactorCount;;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Erdos-Selfridge Class');
use constant description => Math::NumSeq::__('Erdos-Selfridge class of a prime.');
use constant default_i_start => 1;
use constant characteristic_integer => 1;
use constant characteristic_increasing => 0;
use constant characteristic_non_decreasing => 0;
use constant characteristic_smaller => 1;
use constant values_min => 0;

use constant parameter_info_array =>
  [
   { name        => 'p_or_m',
     display     => Math::NumSeq::__('+/-'),
     type        => 'enum',
     default     => '+',
     choices     => ['+','-'],
     choices_display => [Math::NumSeq::__('+'),
                         Math::NumSeq::__('-')],
     description => Math::NumSeq::__('Class + or -, factorizing p+1 or p-1 respectively in the classification.'),
   },
   { name        => 'on_values',
     share_key   => 'on_values_primes',
     display     => Math::NumSeq::__('On Values'),
     type        => 'enum',
     default     => 'all',
     choices     => ['all','primes'],
     choices_display => [Math::NumSeq::__('All'),
                         Math::NumSeq::__('Primes')],
     description => Math::NumSeq::__('Values to classify, either all integers or just the primes.'),
   },
  ];

#------------------------------------------------------------------------------

# cf A098661 cumulative class+
#    A005109 1-, Pierpont
#    A005110 2-
#    A005111 3-
#    A005112 4-
#    A081424 5-
#    A081425 6-
#    A081640 12-
#    A129248 14-
#    A129249 15-
#    A129250 16-
#    A005105 1+
#    A005106 2+
#    A005107 3+
#    A005108 4+
#    A081633 5+
#    ...
#    A081639 11+
#    A084071 12+
#    A090468 13+
#    A129474 14+
#    A129475 15+
#    A178382 in both k+ and k- for some k
#    A005113 least prime in class n+
#    A056637 least prime of class n-
#    A129470 where largest factor of p+1 isn't largest class
#    A129469 first prime of class n+ in A129470
#    A129471 3+ with largest factor of p+1 not in 2+
#    A129472 4+ with largest factor of p+1 not in 3+
#
my %oeis_anum = ('+' => { 'primes' => 'A126433', # class+ of primes
                          'all'    => 'A078442',
                        },
                 '-' => { 'primes' => 'A126805', # class- of primes
                        });
# OEIS-Catalogue: A126433 on_values=primes
# OEIS-Catalogue: A126805 on_values=primes p_or_m=-
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'p_or_m'}}->{$self->{'on_values'}};
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  if ($self->{'on_values'} eq 'primes') {
    $self->{'seq'} = Math::NumSeq::Primes->new;
  }
}
sub next {
  my ($self) = @_;
  my $i = $self->{'i'}++;
  my $value;
  if (my $seq = $self->{'seq'}) {
    (undef, $value) = $self->{'seq'}->next;
  } else {
    $value = $i;
  }
  return ($i, _classify($self,$value));
}

sub ith {
  my ($self, $i) = @_;
  if ($self->{'on_values'} eq 'primes') {
    return undef; # no i'th prime yet
  }
  return _classify($self,$i);
}
sub can {
  my ($class_or_self, $method) = @_;
  if (($method eq 'ith' || $method eq 'seek_to_i')
      && ref $class_or_self
      && $class_or_self->{'on_values'} eq 'primes') {
    return undef;
  }
  return $class_or_self->SUPER::can($method);
}

sub _classify {
  my ($self, $i) = @_;

  Math::NumSeq::Primes->pred($i)
      or return 0;

  my $offset = ($self->{'p_or_m'} eq '+' ? 1 : -1);
  my $ret = 0;
  my @this = ($i);
  while (@this) {
    $ret++;
    my %next;
    foreach my $prime (@this) {
      my ($good, @primes) = _prime_factors($prime + $offset);
      return undef unless $good;

      @next{@primes} = ();  # hash slice, for uniq
    }
    delete @next{2,3}; # hash slice, not 2 or 3
    @this = keys %next;
  }
  return $ret;
}

sub pred {
  my ($self, $value) = @_;
  return ($value >= 0
          && $value == int($value));
}

1;
__END__

=for stopwords Ryde Math-NumSeq ie Erdos Selfridge Erdos-Selfridge

=head1 NAME

Math::NumSeq::ErdosSelfridgeClass -- Erdos-Selfridge classification of primes

=head1 SYNOPSIS

 use Math::NumSeq::ErdosSelfridgeClass;
 my $seq = Math::NumSeq::ErdosSelfridgeClass->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is a class number for primes by Erdos and Selfridge, or 0 for
composites.  The default is "class+"

    0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 2, 0, 0, 0, 1, 0, 2, 0, 0, ...
    starting i=1,

A prime p is classified by factorizing p+1 into primes, then on each of
those primes q factorizing q+1, and so on, repeating until reaching entirely
2s and 3s.  p=2 or p=3 interchange on factorizing p+1 (2+1=3 and 3+1=2*2).

A prime p where p+1 factorizes to all 2s or 3s is class 1.  For example i=11
has 11+1=12=2*2*3 which is all 2s and 3s so class 1.  2 and 3 themselves are
class 1 too, since their p+1 factorizing gives 2s and 3s.

Further primes are classified by how many iterations of the p+1 factorizing
is necessary to reach 2s and 3s.  For example prime p=3847 is iterated as

    3847+1 = 2*13*37

    then 13+1 = 2*7
         37+1 = 2*19

    then 7+1 = 2*2*2
         19+1 = 2*2*5

    then 5+1 = 2*3

So 3847 is class 4 as it took 4 steps to reach all 2s and 3s.  Some of the
factors become 2s and 3s earlier, but the steps continue until all factors
are reduced to 2s and 3s.

=head2 Class -

Option C<p_or_m =E<gt> '-'> applies the same procedure to prime
factors of p-1, giving a "class-" number.

    0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 2, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, ...

It sometimes happens that class+ is the same as class-, but in general the
two are unrelated.

=head2 Primes Only

Option C<on_values =E<gt> 'primes'> selects the classes of just the
primes,

    1, 1, 1, 1, 1, 2, 1, 2, 1, 2, 1, 3, 2, 2, 1, 1, 2, 2, 2, 1, 4, ...

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::ErdosSelfridgeClass-E<gt>new ()>

=item C<$seq = Math::NumSeq::ErdosSelfridgeClass-E<gt>new (p_or_m =E<gt> $str, on_values =E<gt> $str)>

Create and return a new sequence object.

C<p_or_m> (a string) can be

    "+"    factors of p+1 (the default)
    "-"    factors of p-1

C<on_values> (a string) can be

    "all"      classify all integers
    "primes"   classify just the primes

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the class number of C<$value>, or 0 if C<$value> is not a prime.

This method is only available for the default C<on_values=E<gt>'all'>.
C<$seq-E<gt>can('ith')> says whether C<ith()> can be used (and gives a
coderef).

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs as a classification, which means any integer
C<$value E<gt>= 0>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014 Kevin Ryde

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
