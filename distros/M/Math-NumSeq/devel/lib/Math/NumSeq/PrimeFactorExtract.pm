# N_low
# N_high
# N_middle
# position_offset
#



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

package Math::NumSeq::PrimeFactorExtract;
use 5.004;
use strict;
use List::Util qw(min max sum reduce);
use Math::Factor::XS 0.39 'prime_factors'; # version 0.39 for prime_factors()

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');

use Math::NumSeq 7; # v.7 for _is_infinite()
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Extract prime factor from i.');
use constant default_i_start => 1;
use constant characteristic_increasing => 0;

use constant parameter_info_array =>
  [
   {
    name    => 'extract_type',
    type    => 'enum',
    default => 'minimum',
    choices => ['minimum','maximum',
                'mean',
                # 'median',
                'quadratic_mean','geometric_mean',
               ],
   },
   {
    name    => 'on_values',
    type    => 'enum',
    default => 'all',
    choices => ['all','composites',
               ],
   },
  ];

sub values_min {
  my ($self) = @_;
  # if ($self->{'extract_type'} eq 'high') {
  #   return ($self->i_start > 0 ? 1 : 0);
  # }
  return 1;
}

my %type_is_integer = (low => 1,
                       high => 1,
                       second_low => 1,
                       second_high => 1,
                       middle => 1,
                       minimum => 1,
                       maximum => 1,
                       mean => 0,
                       median => 0,
                       mode => 0,
                       geometric_mean => 0,
                       quadratic_mean => 0,
                      );
sub characteristic_integer {
  my ($self) = @_;
  return $type_is_integer{$self->{'extract_type'}};
}


#------------------------------------------------------------------------------
# cf A118663 prime index of least prime dividing the composites

my %oeis_anum;

$oeis_anum{'all'}->{'minimum'} = 'A020639';
# OEIS-Catalogue: A020639 extract_type=min

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'on_values'}}->{$self->{'extract_type'}};
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  if ($self->{'on_values'} eq 'composites') {
    require Math::NumSeq::Primes;
    my $seq = $self->{'primes_seq'} = Math::NumSeq::Primes->new;
    $self->{'upto'} = 0;
    $self->{'next_prime'} = 0;
  }
}

sub next {
  my ($self) = @_;
  ### PrimeFactorExtract next(): $self->{'i'}

  my $i = $self->{'i'}++;
  my $value;
  if ($self->{'on_values'} eq 'composites') {
    until (($value = $self->{'upto'}++) < $self->{'next_prime'}) {
      (undef, $self->{'next_prime'}) = $self->{'primes_seq'}->next;
    }
  } else {
    $value = $i;
  }
  ### $value

  my @primes = prime_factors($value)
    or return ($i, $value);  # value=0 or 1 no factors
  ### @primes

  my $extract_type = $self->{'extract_type'};
  if ($extract_type eq 'minimum') {
    $value = min(@primes);
  } elsif ($extract_type eq 'maximum') {
    $value = max(@primes);
  } elsif ($extract_type eq 'mean') {
    $value = sum(@primes)/scalar(@primes);

  } elsif ($extract_type eq 'median') {
    # 6 digits 0,1,2,3,4,5 int(6/2)=3 is up
    # 6 digits 0,1,2,3,4,5 int((6-1)/2)=2 is down
    # 7 digits 0,1,2,3,4,5,6 int(7/2)=3
    # 7 digits 0,1,2,3,4,5,6 int((7-1)/2)=3 too
    @primes = sort {$a<=>$b} @primes;

    # mean if even
    $value = ($primes[$#primes/2] + $primes[scalar(@primes)/2]) / 2;

    # $value = $primes[$#primes/2]; # round down
  } elsif ($extract_type eq 'quadratic_mean') {
    $value = sqrt(sum(map{$_*$_}@primes)/scalar(@primes));

  } elsif ($extract_type eq 'geometric_mean') {
    $value = (reduce {$a*$b} @primes) ** (1/scalar(@primes));

  }
  return ($i, $value);

  # if ($self->{'round'} eq 'up') {
  #   return $primes[scalar(@primes)/2];
  # }
  # if ($self->{'round'} eq 'down') {
  # }
  # return ($primes[$#primes/2] + $primes[scalar(@primes)/2]) / 2;
  # if ($extract_type eq 'middle') {
  #   if ($self->{'round'} eq 'up') {
  #     return $primes[scalar(@primes)/2];
  #   }
  #   if ($self->{'round'} eq 'down') {
  #     return $primes[$#primes/2];
  #   }
  # }
  # if ($extract_type eq 'mode') {
  #   my @count;
  #   my $max_count = 0;
  #   foreach my $digit (@primes) {
  #     if (++$count[$digit] > $max_count) {
  #       $max_count = $count[$digit];
  #     }
  #   }
  #   my $sum = 0;
  #   my $sumcount = 0;
  #   my $last = 0;
  #   foreach my $digit (0 .. $#count) {
  #     if (($count[$digit]||0) == $max_count) {
  #       if ($self->{'round'} eq 'down') {
  #         return $digit;
  #       }
  #       $sum += $digit; $sumcount++;
  #       $last = $digit;
  #     }
  #   }
  #   if ($self->{'round'} eq 'up') {
  #     return $last;
  #   }
  #   return $sum/$sumcount;
  # }
  #
  # my $ret;
  # if ($extract_type eq 'mean') {
  #   $ret = List::Util::sum(@primes) / scalar(@primes);
  #
  # } else {
  #   die "Unrecognised extract_type: ",$extract_type;
  # }
  #
  # if ($self->{'round'} eq 'down') {
  #   return int($ret);
  # }
  # if ($self->{'round'} eq 'up') {
  #   my $int = int($ret);
  #   return $int + ($ret != int($ret));
  # }
  # return $ret;
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::PrimeFactorExtract -- prime factor extracted from integers

=head1 SYNOPSIS

 use Math::NumSeq::PrimeFactorExtract;
 my $seq = Math::NumSeq::PrimeFactorExtract->new (extract_type => 'minimum');
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

I<In progress ...>

Extract one of the prime factors from i.  C<extract_type> (a string) can be

    "minimum"       smallest prime factor
    "maximum"       largest prime factor
    "mean"          average prime factor

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for the behaviour common to all path classes.

=over 4

=item C<$seq = Math::NumSeq::PrimeFactorExtract-E<gt>new (extract_type =E<gt> $str)>

Create and return a new sequence object.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
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
