# N_low
# N_high
# N_middle
#
# DigitExtract
# DigitAverage

# mean
# geometric_mean
# quadratic_mean
# median_min
# median_max
# median_mean
# median_average
# mode_min
# mode_max
# mode_mean
# middle_high
# middle_low
# middle_mean



# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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

package Math::NumSeq::DigitExtract;
use 5.004;
use strict;
use List::Util qw(min max sum reduce);

use vars '$VERSION', '@ISA';
$VERSION = 72;

use Math::NumSeq::Base::IterateIth;
use Math::NumSeq::Base::Digits;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq::Base::Digits');

use Math::NumSeq 7; # v.7 for _is_infinite()
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Modulo;
use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Extract digit from i.');
use constant default_i_start => 0;
use constant characteristic_increasing => 0;

use constant parameter_info_array =>
  [
   Math::NumSeq::Base::Digits::parameter_common_radix(),
   { name    => 'extract_type',
     type    => 'enum',
     default => 'low',
     choices => ['low','high',
                 'middle_lower','middle_higher',
                 'minimum','maximum',

                 # 'second_low','second_high',
                 # 'mean',
                 # # 'median',
                 # # 'mode',
                 # 'geometric_mean',
                 # 'quadratic_mean',
                ],
   },
   { name    => 'extract_offset',
     type    => 'integer',
     default => 0,
     width   => 3,
   },
   { name    => 'round',
     # display => Math::NumSeq::__('Round'),
     type    => 'enum',
     default => 'unrounded',
     choices => ['unrounded',
                 # 'floor', 'ceil', 'nearest'
                ],
     description => Math::NumSeq::__('Rounding direction'),
   },
  ];

sub values_min {
  my ($self) = @_;
  if ($self->i_start > 0
      && (($self->{'extract_type'} eq 'high' && $self->{'extract_offset'} == 0)
          || $self->{'extract_type'} eq 'maximum')) {
    return 1;  # high digit >= 1
  }
  return 0;
}

my %type_is_integer = (low => 1,
                       high => 1,
                       middle_lower => 1,
                       middle_higher => 1,
                       minimum => 1,
                       maximum => 1,

                       mean => 0,
                       median => 0,
                       mode => 0,
                       geometric_mean => 0,
                       quadratic_mean => 0,
                      );
my %round_is_integer = (floor   => 1,
                        ceil    => 1,
                        nearest => 1);
sub characteristic_integer {
  my ($self) = @_;
  return $type_is_integer{$self->{'extract_type'}}
    || $round_is_integer{$self->{'round'}};
}


#------------------------------------------------------------------------------
my @oeis_anum;

# ENHANCE-ME: low is n mod radix -- anum by radix

# cf A134777 minimum alphabetical english names of digits
#    A134778 minimum alphabetical english names of digits
#    A061383 arithmetic mean is an integer
#    A180157 arithmetic mean is not an integer
#    A175688 arithmetic mean is an integer and one of the digits
#    A180160 sum digits mod num digits
#    A037897 base 3 maxdigit-mindigit
#    A060420 minimum digit of the primes
#    A077648 high digit of the primes
#    A044959 numbers with a distinct mode, ie. unique most populous
#    A141391 when RMS is an integer
#    A038374 length longest run of 1-bits
#
#    A175262 binary odd num digits and middle digit is 0
#    A175263 binary odd num digits and middle digit is 1

#----------
# low digit

# OEIS-Other: A000035 extract_type=low radix=2
# OEIS-Other: A010879 extract_type=low

$oeis_anum[0]->{'low'}->{'floor'}
  = $oeis_anum[0]->{'low'}->{'ceil'}
  = $oeis_anum[0]->{'low'}->{'unrounded'};

# A133873 radix=2 second lowest, not quite OFFSET=0 starts 1,1,1,2,2,2,0,0,0
# $oeis_anum[0]->{'low'}->{'unrounded'}->[1]->[3]  = 'A133873';  # radix=3

#----------
# high digit

$oeis_anum[1]->{'high'}->{'unrounded'}->[0]->[3] = 'A122586'; # starting OFFSET=1
$oeis_anum[1]->{'high'}->{'unrounded'}->[0]->[4] = 'A122587'; # starting OFFSET=1
$oeis_anum[0]->{'high'}->{'unrounded'}->[0]->[10] = 'A000030';
# OEIS-Catalogue: A122586 extract_type=high radix=3 i_start=1
# OEIS-Catalogue: A122587 extract_type=high radix=4 i_start=1
# OEIS-Catalogue: A000030 extract_type=high
$oeis_anum[0]->{'high'}->{'floor'}
  = $oeis_anum[0]->{'high'}->{'ceil'}
  = $oeis_anum[0]->{'high'}->{'unrounded'};

#----------
# middle digit

# A179635 digit to the left, meaning higher
$oeis_anum[1]->{'middle_higher'}->{'unrounded'}->[0]->[10] = 'A179635';
$oeis_anum[1]->{'middle_lower'}->{'unrounded'}->[0]->[10]  = 'A179636';
# OEIS-Catalogue: A179635 extract_type=middle_higher i_start=1
# OEIS-Catalogue: A179636 extract_type=middle_lower  i_start=1

#----------
# minimum digit

$oeis_anum[0]->{'minimum'}->{'unrounded'}->[0]->[10] = 'A054054';
# OEIS-Catalogue: A054054 extract_type=minimum
$oeis_anum[0]->{'minimum'}->{'floor'}
  = $oeis_anum[0]->{'minimum'}->{'ceil'}
  = $oeis_anum[0]->{'minimum'}->{'unrounded'};

#----------
# maximum digit

$oeis_anum[0]->{'maximum'}->{'unrounded'}->[0]->[3] = 'A190592';
$oeis_anum[0]->{'maximum'}->{'unrounded'}->[0]->[4] = 'A190593';
$oeis_anum[0]->{'maximum'}->{'unrounded'}->[0]->[5] = 'A190594';
$oeis_anum[0]->{'maximum'}->{'unrounded'}->[0]->[6] = 'A190595';
$oeis_anum[0]->{'maximum'}->{'unrounded'}->[0]->[7] = 'A190596';
$oeis_anum[0]->{'maximum'}->{'unrounded'}->[0]->[8] = 'A190597';
$oeis_anum[0]->{'maximum'}->{'unrounded'}->[0]->[9] = 'A190598';
$oeis_anum[0]->{'maximum'}->{'unrounded'}->[0]->[10] = 'A054055';
$oeis_anum[0]->{'maximum'}->{'unrounded'}->[0]->[11] = 'A190599';
$oeis_anum[0]->{'maximum'}->{'unrounded'}->[0]->[12] = 'A190600';
# OEIS-Catalogue: A190592 extract_type=maximum radix=3
# OEIS-Catalogue: A190593 extract_type=maximum radix=4
# OEIS-Catalogue: A190594 extract_type=maximum radix=5
# OEIS-Catalogue: A190595 extract_type=maximum radix=6
# OEIS-Catalogue: A190596 extract_type=maximum radix=7
# OEIS-Catalogue: A190597 extract_type=maximum radix=8
# OEIS-Catalogue: A190598 extract_type=maximum radix=9
# OEIS-Catalogue: A054055 extract_type=maximum
# OEIS-Catalogue: A190599 extract_type=maximum radix=11
# OEIS-Catalogue: A190600 extract_type=maximum radix=12
$oeis_anum[0]->{'maximum'}->{'floor'}
  = $oeis_anum[0]->{'maximum'}->{'ceil'}
  = $oeis_anum[0]->{'maximum'}->{'unrounded'};

#----------
# mean digit, rounded

$oeis_anum[0]->{'mean'}->{'floor'}->[10] = 'A004426';
$oeis_anum[0]->{'mean'}->{'ceil'}->[10]   = 'A004427';
# OEIS-Catalogue: A004426 extract_type=mean round=floor
# OEIS-Catalogue: A004427 extract_type=mean round=ceil

$oeis_anum[0]->{'geometric_mean'}->{'floor'}->[10]   = 'A004428';
$oeis_anum[0]->{'geometric_mean'}->{'nearest'}->[10] = 'A004429';
$oeis_anum[0]->{'geometric_mean'}->{'ceil'}->[10]    = 'A004430';
# OEIS-Catalogue: A004428 extract_type=geometric_mean round=floor
# OEIS-Catalogue: A004429 extract_type=geometric_mean round=nearest
# OEIS-Catalogue: A004430 extract_type=geometric_mean round=ceil

# $oeis_anum[0]->{'median'}->{'floor'}->[10] = '';
# $oeis_anum[0]->{'median'}->{'ceil'}->[10]   = ''
# # OEIS-Catalogue:  extract_type=median round=floor
# # OEIS-Catalogue:  extract_type=median round=ceil

$oeis_anum[0]->{'mode'}->{'floor'}->[2] = 'A115516';  # mode of bits
$oeis_anum[0]->{'mode'}->{'ceil'}->[2]   = 'A115517';
# OEIS-Catalogue: A115516 extract_type=mode round=floor radix=2
# OEIS-Catalogue: A115517 extract_type=mode round=ceil radix=2
$oeis_anum[0]->{'mode'}->{'floor'}->[10] = 'A115353';  # mode of decimal
# OEIS-Catalogue: A115353 extract_type=mode round=floor

sub oeis_anum {
  my ($self) = @_;
  my $radix = $self->{'radix'};

  if ($self->{'extract_type'} eq 'low'
      && $self->{'extract_offset'} == 0) {
    return Math::NumSeq::Modulo::_modulus_to_anum($radix);
  }

  ### lookup: $oeis_anum[$self->i_start]->{$self->{'extract_type'}}->{$self->{'round'}}

  return $oeis_anum[$self->i_start]
    ->{$self->{'extract_type'}}->{$self->{'round'}}
      ->[$self->{'extract_offset'}]->[$radix];
}

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  unless ($self->{'extract_type'} =~ /middle/) {
    $self->{'extract_offset'} = abs($self->{'extract_offset'});
  }
  return $self;
}

sub ith {
  my ($self, $i) = @_;
  ### DigitExtract ith(): $i

  $i = abs($i);
  if (_is_infinite($i)) {
    return $i;  # don't loop forever if $i is +infinity
  }

  my $radix = $self->{'radix'};
  my $extract_type   = $self->{'extract_type'};
  my $extract_offset = $self->{'extract_offset'};

  if ($extract_type eq 'low') {
    my $ret = 0;
    foreach (0 .. $extract_offset) {
      $ret = _divrem_mutate($i,$radix);
    }
    return $ret;
  }

  my @digits = _digit_split_lowtohigh($i, $radix);

  if ($extract_type eq 'high') {
    $extract_offset = $#digits - $extract_offset;
  } elsif ($extract_type eq 'middle_lower') {
    # 1,2,3    $#digits = 2, middle_lower=int(2/2)=1
    # 1,2,3,4  $#digits = 3, middle_lower=int(3/2)=1
    $extract_offset += int($#digits/2);
  } elsif ($extract_type eq 'middle_higher') {
    #   3,2,1  $#digits = 2, middle_higher=int(3/2)=1
    # 4,3,2,1  $#digits = 3, middle_higher=int(4/2)=2
    $extract_offset += int(scalar(@digits)/2);
  } else {
    ### assert: $extract_type eq 'minimum' || $extract_type eq 'maximum'
    @digits = sort {$a<=>$b} @digits;  # ascending order
    if ($extract_type eq 'maximum') {
      $extract_offset = $#digits - $extract_offset;
    }
  }
  return ($extract_offset < 0 ? 0
          : ($digits[$extract_offset] || 0));


  # if ($extract_type eq 'middle') {
  #   if ($self->{'round'} eq 'ceil') {
  #     return $digits[scalar(@digits)/2];
  #   }
  #   if ($self->{'round'} eq 'floor') {
  #     return $digits[$#digits/2];
  #   }
  #   return ($digits[$#digits/2] + $digits[scalar(@digits)/2]) / 2;
  # }
  # if ($extract_type eq 'median') {
  #   # 6 digits 0,1,2,3,4,5 int(6/2)=3 is ceil
  #   # 6 digits 0,1,2,3,4,5 int((6-1)/2)=2 is floor
  #   # 7 digits 0,1,2,3,4,5,6 int(7/2)=3
  #   # 7 digits 0,1,2,3,4,5,6 int((7-1)/2)=3 too
  #   @digits = sort {$a<=>$b} @digits;
  #   if ($self->{'round'} eq 'ceil') {
  #     return $digits[scalar(@digits)/2];
  #   }
  #   if ($self->{'round'} eq 'floor') {
  #     return $digits[$#digits/2];
  #   }
  #   return ($digits[$#digits/2] + $digits[scalar(@digits)/2]) / 2;
  # }
  # if ($extract_type eq 'mode') {
  #   my @count;
  #   my $max_count = 0;
  #   foreach my $digit (@digits) {
  #     if (++$count[$digit] > $max_count) {
  #       $max_count = $count[$digit];
  #     }
  #   }
  #   my $sum = 0;
  #   my $sumcount = 0;
  #   my $last = 0;
  #   foreach my $digit (0 .. $#count) {
  #     if (($count[$digit]||0) == $max_count) {
  #       if ($self->{'round'} eq 'floor') {
  #         return $digit;
  #       }
  #       $sum += $digit; $sumcount++;
  #       $last = $digit;
  #     }
  #   }
  #   if ($self->{'round'} eq 'ceil') {
  #     return $last;
  #   }
  #   return $sum/$sumcount;
  # }
  #
  # my $ret;
  # if ($extract_type eq 'mean') {
  #   $ret = sum(@digits) / scalar(@digits);
  #
  # } elsif ($extract_type eq 'geometric_mean') {
  #   $ret = (reduce {$a*$b} @digits) ** (1/scalar(@digits));
  #
  # } elsif ($extract_type eq 'quadratic_mean') {
  #   $ret = sqrt(sum(map{$_*$_}@digits)/scalar(@digits));
  #
  # } else {
  #   die "Unrecognised extract_type: ",$extract_type;
  # }
  #
  # if ($self->{'round'} eq 'floor') {
  #   return int($ret);
  # }
  # if ($self->{'round'} eq 'ceil') {
  #   my $int = int($ret);
  #   return $int + ($ret != int($ret));
  # }
  # if ($self->{'round'} eq 'nearest') {
  #   return int($ret+0.5);
  # }
  # return $ret;
}

#------------------------------------------------------------------------------

# return $remainder, modify $n
# the scalar $_[0] is modified, but if it's a BigInt then a new BigInt is made
# and stored there, the bigint value is not changed
sub _divrem_mutate {
  my $d = $_[1];
  my $rem;
  if (ref $_[0] && $_[0]->isa('Math::BigInt')) {
    ($_[0], $rem) = $_[0]->copy->bdiv($d);  # quot,rem in array context
    if (! ref $d || $d < 1_000_000) {
      return $rem->numify;  # plain remainder if fits
    }
  } else {
    $rem = $_[0] % $d;
    $_[0] = int(($_[0]-$rem)/$d); # exact division stays in UV
  }
  return $rem;
}

1;
__END__

#     "mean"              average sum/n
#     "geometric_mean"    nthroot(product)
#     "quadratic_mean"    sqrt(sumsquares/n)
#     "median"            middle digit when sorted
#     "mode"              most frequent digit
# 
# For "middle" and "median" when there's an even number of digits the average
# (mean) of the two middle ones is returned, or the C<round> parameter can be
# "ceil" or "floor" to go to the more/less significant for the middle or the
# higher/lower for the median.
# 
# For the averages the result is a fractional value in general, but the
# C<round> parameter "ceil" or "floor can round to the next integer.

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::DigitExtract -- one of the digits of integers 0 upwards

=head1 SYNOPSIS

 use Math::NumSeq::DigitExtract;
 my $seq = Math::NumSeq::DigitExtract->new (extract_type => 'median');
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

I<In progress ...>

Extract one of the digits from the index i.  The default is to extract the
lowest decimal digit,

    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, ...
    starting i=0

The C<extract_type> option (a string) gives which digit to extract

    "low"               least significant digit
    "high"              most significant digit
    "middle_lower"      second least significant digit
    "middle_higher"     second most significant digit
    "minimum"           smallest digit
    "maximum"           largest digit

For an even number of digits "middle_lower" selects the lower position one
and "middle_higher" selects the higher position one.

Option C<radix =E<gt> $integer> selects a base other than decimal.

=head2 Offset

Option C<extract_offset =E<gt> $integer> can select the digit at a position
offset from the C<extract_type>.  For example with the default "low" an
offset of 1 gives the second lowest digit,

    extract_offset=>1
    0,0,0,0,0,0,0,0,0,0, 1,1,1,1,1,1,1,1,1,1, 2,2,2,2,2,2,2,2,2,2,

For "minimum" and "maximum" the digits are imagined sorted into increasing
or decreasing order then the C<extract_offset> applied to select from there.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for the behaviour common to all path classes.

=over 4

=item C<$seq = Math::NumSeq::DigitExtract-E<gt>new (extract_type =E<gt> $integer, extract_offset =E<gt> $integer, radix =E<gt> $integer)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th value from the sequence.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitCount>,
L<Math::NumSeq::DigitLength>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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
