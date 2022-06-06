# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

package Math::NumSeq::Emirps;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;
use Math::NumSeq;
use Math::NumSeq::Primes;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;


# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Emirps');
use constant description => Math::NumSeq::__('Numbers which are primes forwards and backwards, eg. 157 because both 157 and 751 are primes.  Palindromes like 131 are excluded.  Default is decimal, or select a radix.');

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

# FIXME: find the first value in the sequence ... maybe save it
my @values_min;
$values_min[2]  = 11; # binary 1011 reverse 1101 is decimal 13
$values_min[10] = 13; # reverse to 31
sub values_min {
  my ($self) = @_;
  return $values_min[$self->{'radix'}];
}

#------------------------------------------------------------------------------
# A006567 - decimal reversal is a prime and different
# A007500 - decimal reversal is a prime, so palindromes which are primes too
#
my @oeis_anum;
$oeis_anum[2] = 'A080790';
$oeis_anum[10] = 'A006567';
# OEIS-Catalogue: A080790 radix=2
# OEIS-Catalogue: A006567 radix=10
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'primes_seq'} = Math::NumSeq::Primes->new;
}

# ENHANCE-ME: The commented out code below took blocks of primes by radix
# powers and filtered.  More memory but faster.
#
# ENHANCE-ME: No need to examine blocks where the high digit is even, or
# where it has a common factor with the radix.
#
sub next {
  my ($self) = @_;

  my $primes_seq = $self->{'primes_seq'};

  for (;;) {
    (undef, my $prime) = $primes_seq->next
      or return;
    my $rev = _reverse_in_radix($prime,$self->{'radix'});

    ### consider: $prime
    ### $rev

    if ($rev != $prime && $self->Math::NumSeq::Primes::pred($rev)) {
      ### yes ...
      return ($self->{'i'}++, $prime);
    }
  }
}

# ENHANCE-ME: are_all_prime() to look for small divisors in both values
# simultaneously, in case the reversal is even etc and easily excluded.
sub pred {
  my ($self, $value) = @_;
  if (_is_infinite($value)) {
    return 0;
  }
  my $rev = _reverse_in_radix($value,$self->{'radix'});
  return ($rev != $value
          && $self->Math::NumSeq::Primes::pred($value)
          && $self->Math::NumSeq::Primes::pred(_reverse_in_radix($value,$self->{'radix'})));
}

# return $n reversed in $radix
sub _reverse_in_radix {
  my ($n, $radix) = @_;

  if ($radix == 10) {
    return scalar(reverse("$n"));
  } else {
    my $ret = $n*0;   # inherit bignum 0
    # ### _reverse_in_radix(): sprintf '%#X %d', $n, $n
    do {
      $ret = $ret * $radix + ($n % $radix);
    } while ($n = int($n/$radix));
    # ### ret: sprintf '%#X %d', $ret, $ret
    return $ret;
  }
}

1;
__END__


# sub _digits_in_radix {
#   my ($n, $radix) = @_;
#   return 1 + int(log($n)/log($radix));
# }
# 
# sub new {
#   my ($class, %options) = @_;
#   ### Emirps new()
# 
#   my $lo = $options{'lo'} || 0;
#   my $hi = $options{'hi'};
#   my $radix = $options{'radix'} || $class->parameter_default('radix');
#   if ($radix < 2) { $radix = 10; }
#   $lo = max (10, $lo);
#   $hi = max ($lo, $hi);
# 
#   my $primes_lo = $radix ** (_digits_in_radix($lo,$radix) - 1) - 1;
#   my $primes_hi = $radix ** _digits_in_radix($hi,$radix) - 1;
#   #
#   ### Emirps: "$lo to $hi radix $radix"
#   ### using primes: "$primes_lo to $primes_hi"
#   ### digits: _digits_in_radix($lo,$radix).' to '._digits_in_radix($hi,$radix)
# 
#   # Math::NumSeq::Primes->new (lo => $primes_lo,
#   #                                      hi => $primes_hi);
# 
#   require Math::NumSeq::Primes;
#   my @array = Math::NumSeq::Primes::_primes_list
#     ($primes_lo, $primes_hi);
# 
#   my %primes;
#   @primes{@array} = ();
#   if ($radix == 10) {
#     @array = grep {
#       $_ >= $lo && $_ <= $hi && do {
#         my $r;
#         ((($r = reverse $_) != $_) && exists $primes{$r})
#       }
#     } @array;
#   } else {
#     @array = grep {
#       $_ >= $lo && $_ <= $hi && do {
#         my $r;
#         (($r = _reverse_in_radix($_,$radix)) != $_ && exists $primes{$r})
#       }
#     } @array;
#   }
#   ### @array
# 
#   return $class->SUPER::new (%options,
#                              radix => $radix,
#                              array => \@array);
# }

=for stopwords Ryde Math-NumSeq emirp emirps

=head1 NAME

Math::NumSeq::Emirps -- primes backwards and forwards

=head1 SYNOPSIS

 use Math::NumSeq::Emirps;
 my $seq = Math::NumSeq::Emirps->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The "emirps", being numbers which are primes backwards and forwards.  For
example 157 is an emirp because both 157 and its reverse 751 are primes.
Prime palindromes are excluded.

The default base is decimal, or the C<radix> parameter can select another
base.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Emirps-E<gt>new ()>

=item C<$seq = Math::NumSeq::Emirps-E<gt>new (radix =E<gt> 16)>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is an emirp, meaning it and its digit reversal (in
the C<radix>) are both primes.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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
