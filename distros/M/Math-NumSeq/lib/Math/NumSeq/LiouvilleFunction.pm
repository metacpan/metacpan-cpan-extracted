# Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::LiouvilleFunction;
use 5.004;
use strict;
use List::Util 'max','min';

use vars '$VERSION','@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');

use Math::NumSeq::PrimeFactorCount;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Liouville Function');
use constant default_i_start => 1;

use constant parameter_info_array =>
  [ {
     name    => 'values_type',
     share_key => 'values_type_1-1_01_10',
     type    => 'enum',
     default => '1,-1',
     choices => ['1,-1',
                 '0,1',
                 '1,0',
                ],
     # TRANSLATORS: "1,-1" offered for translation of the "," if that might look like a decimal point, otherwise can be left unchanged
     choices_display => [Math::NumSeq::__('1,-1'),
                         Math::NumSeq::__('0,1'),
                         Math::NumSeq::__('1,0'),
                        ],
     description => Math::NumSeq::__('The values to give for even or odd parity.'),
    },
  ];

sub description {
  my ($self) = @_;
  my ($even,$odd) = (ref $self ? @{$self->{'values'}} : (1,-1));
  # ENHANCE-ME: use __x(), maybe
  return sprintf(Math::NumSeq::__('The Liouville function, being %s for an even number of prime factors or %s for an odd number.'),
                 $even, $odd);
}

use constant characteristic_increasing => 0;
sub characteristic_integer {
  my ($self) = @_;
  return (_is_integer($self->{'values_min'})
          && _is_integer($self->{'values_max'}));
}
sub characteristic_pn1 {
  my ($self) = @_;
  return ($self->{'values_min'} == -1 && $self->{'values_max'} == 1);
}

#------------------------------------------------------------------------------
# cf A026424  the -1 positions, odd number of primes
#    A028260  the 1 positions, even number of primes
#    A072203  cumulative +/-1
#    A055038  cumulative 1=odd
#    A028488  where cumulative==0
#    A051470  first cumulative==n

my %oeis_anum = ('1,-1' => 'A008836',  # liouville 1,-1
                 '0,1'  => 'A066829',  # 0 and 1
                 '1,0'  => 'A065043',  # 1 and 0
                 # OEIS-Catalogue: A008836
                 # OEIS-Catalogue: A066829 values_type=0,1
                 # OEIS-Catalogue: A065043 values_type=1,0
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{join(',',@{$self->{'values'}})};
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  my @values = split /,/, $self->{'values_type'};
  $self->{'values'} = \@values;
  $self->{'values_min'} = min(@values);
  $self->{'values_max'} = max(@values);
  return $self;
}

sub ith {
  my ($self, $i) = @_;
  ### LiouvilleFunction ith(): $i

  my ($good, @primes) = _prime_factors($i);
  return ($good
          ? $self->{'values'}->[scalar(@primes) & 1]
          : undef);
}

sub pred {
  my ($self, $value) = @_;
  return ($value == $self->{'values'}->[0]
          || $value == $self->{'values'}->[1]);
}

#------------------------------------------------------------------------------
# generic

sub _is_integer {
  my ($n) = @_;
  return ($n == int($n));
}

1;
__END__

# This was next() done by sieve, but it's scarcely faster than ith() and
# uses a lot of memory if call next() for a long time.
#
# # each 2-bit vec() value is
# #    0 unset
# #    1 (unused)
# #    2 even count of factors
# #    3 odd count of factors
# 
# sub rewind {
#   my ($self) = @_;
#   $self->{'i'} = $self->i_start;
#   _restart_sieve ($self, 500);
# }
# sub _restart_sieve {
#   my ($self, $hi) = @_;
#   ### _restart_sieve() ...
#   $self->{'hi'} = $hi;
#   $self->{'string'} = "\0" x (($hi+1)/4);  # 4 of 2 bits each
#   vec($self->{'string'}, 0,2) = 1;  # N=0 ...
#   vec($self->{'string'}, 1,2) = 2;  # N=1 treated as even
# }
# 
# sub next {
#   my ($self) = @_;
# 
#   my $i = $self->{'i'}++;
#   my $hi = $self->{'hi'};
#   if ($i <= 1) {
#     return ($i, $self->{'values'}->[0]);
#   }
# 
#   my $start = $i;
#   if ($i > $hi) {
#     _restart_sieve ($self, $hi *= 2);
#     $start = 2;
#   }
#   my $sref = \$self->{'string'};
# 
#   my $ret;
#   foreach my $i ($start .. $i) {
#     $ret = vec($$sref, $i,2);
#     if ($ret == 0) {
#       ### prime: $i
#       $ret = 3; # odd
# 
#       # existing squares $v==1 left alone, others toggle 2=odd,3=even
# 
#       for (my $power = $i; $power <= $hi; $power *= $i) {
#         for (my $j = $power; $j <= $hi; $j += $power) {
#           ### p: "$j ".vec($$sref, $j,2)
#           vec($$sref, $j,2) = (vec($$sref, $j,2) ^ 1) | 2;
#           ### set: vec($$sref, $j,2)
#         }
#       }
# 
#       # print "applied: $i\n";
#       # for (my $j = 0; $j < $hi; $j++) {
#       #   printf "  %2d %2d\n", $j, vec($$sref,$j,2);
#       # }
#     }
#   }
#   ### ret: "$i, $ret -> ".$self->{'values'}->[$ret-2]
#   return ($i, $self->{'values'}->[$ret-2]);
# }


=for stopwords Math-NumSeq Ryde Liouville ie

=head1 NAME

Math::NumSeq::LiouvilleFunction -- Liouville function sequence

=head1 SYNOPSIS

 use Math::NumSeq::LiouvilleFunction;
 my $seq = Math::NumSeq::LiouvilleFunction->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The Liouville function parity of the prime factors of i,

    1, -1, -1, 1, -1, 1, -1, -1, 1, 1, -1, -1, -1, 1, 1, ...
    starting i=1

being

    1   if i has an even number of prime factors
    -1  if i has an odd number of prime factors

The sequence starts from i=1 which is taken to be no prime factors,
ie. zero, which is even, hence value 1.  Then i=2 and i=3 are -1 since they
have one prime factor (they're primes), and i=4 is value 1 because it's 2*2
which is an even number of prime factors (two 2s).

This parity is similar to the C<MobiusFunction>, but here repeated prime
factors are included, whereas in C<MobiusFunction> they give a value 0.

=head2 Values Type

The C<values_type> parameter can change the two values returned for even or
odd prime factors.  "0,1" gives 0 for even and 1 for odd, the same as the
count mod 2,

    values_type => '0,1'
    0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, ...

Or "1,0" the other way around, 1 for even, 0 for odd,

    values_type => '1,0'
    1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1, ...

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::LiouvilleFunction-E<gt>new ()>

=item C<$seq = Math::NumSeq::LiouvilleFunction-E<gt>new (values_type =E<gt> $str)>

Create and return a new sequence object.  Optional C<values_type> (a string)
can be

    "1,-1"     1=even, -1=odd  (the default)
    "0,1"      0=even, 1=odd
    "1,0"      1=even, 0=odd

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the Liouville function of C<$i>, being 1 or -1 (or other
C<values_type>) according to the number of prime factors in C<$i>.

This calculation requires factorizing C<$i> and in the current code after
small factors a hard limit of 2**32 is enforced in the interests of not
going into a near-infinite loop.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, which simply means 1 or -1,
or the two C<values_type> values.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::MobiusFunction>,
L<Math::NumSeq::PrimeFactorCount>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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
