# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2018, 2019, 2020 Kevin Ryde

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

package Math::NumSeq::AlmostPrimes;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;
use Math::NumSeq;
@ISA = ('Math::NumSeq');

use Math::NumSeq::Primes;
use Math::NumSeq::Primorials;

# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Almost Primes');
use constant description => Math::NumSeq::__('Products of a fixed number of primes, default the semi-primes, 4, 6, 9, 10, 14 15, etc with just two prime factors P*Q.');
use constant i_start => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

use constant parameter_info_array =>
  [
   { name    => 'factor_count',
     display => Math::NumSeq::__('Factor Count'),
     type    => 'integer',
     default => 2,
     minimum => 2,
     width   => 2,
     description => Math::NumSeq::__('How many prime factors to include.'),
   },
   { name    => 'multiplicity',
     display => Math::NumSeq::__('Multiplicity'),
     type    => 'enum',
     choices => ['repeated','distinct'],
     choices_display => [Math::NumSeq::__('Repeated'),
                         Math::NumSeq::__('Distinct'),
                        ],
     default => 'repeated',
     # description => Math::NumSeq::__(''),
   },
  ];

# cf A068318 - sum of the prime factors of the nth semiprime
#
my %oeis_anum
  = (repeated =>
     [ undef,
       'A000040',  # 1, just the primes
       'A001358',  # 2 with repeats
       'A014612',  # 3 with repeats
       'A014613',  # 4 with repeats
       'A014614',  # 5 with repeats
       'A046306',  # 6 with repeats
       'A046308',  # 7 with repeats
       'A046310',  # 8 with repeats
       'A046312',  # 9 with repeats
       'A046314',  # 10 with repeats
       'A069272',  # 11 with repeats
       'A069273',  # 12 with repeats
       'A069274',  # 13 with repeats
       'A069275',  # 14 with repeats
       'A069276',  # 15 with repeats
       'A069277',  # 16 with repeats
       'A069278',  # 17 with repeats
       'A069279',  # 18 with repeats
       'A069280',  # 19 with repeats
       'A069281',  # 20 with repeats
       # OEIS-Other:     A000040 factor_count=1
       # OEIS-Catalogue: A001358
       # OEIS-Catalogue: A014612 factor_count=3
       # OEIS-Catalogue: A014613 factor_count=4
       # OEIS-Catalogue: A014614 factor_count=5
       # OEIS-Catalogue: A046306 factor_count=6
       # OEIS-Catalogue: A046308 factor_count=7
       # OEIS-Catalogue: A046310 factor_count=8
       # OEIS-Catalogue: A046312 factor_count=9
       # OEIS-Catalogue: A046314 factor_count=10
       # OEIS-Catalogue: A069272 factor_count=11
       # OEIS-Catalogue: A069273 factor_count=12
       # OEIS-Catalogue: A069274 factor_count=13
       # OEIS-Catalogue: A069275 factor_count=14
       # OEIS-Catalogue: A069276 factor_count=15
       # OEIS-Catalogue: A069277 factor_count=16
       # OEIS-Catalogue: A069278 factor_count=17
       # OEIS-Catalogue: A069279 factor_count=18
       # OEIS-Catalogue: A069280 factor_count=19
       # OEIS-Catalogue: A069281 factor_count=20
     ],
     distinct =>
     [ undef,
       'A000040', # 1, just the primes
       'A006881', # 2 distinct primes
       'A007304', # 3 distinct primes
       'A046386', # 4 distinct primes
       'A046387', # 5 distinct primes
       'A067885', # 6 distinct primes
       'A123321', # 7 distinct primes
       'A123322', # 8 distinct primes
       'A115343', # 9 distinct primes
       # OEIS-Other:     A000040 multiplicity=distinct factor_count=1
       # OEIS-Catalogue: A006881 multiplicity=distinct
       # OEIS-Catalogue: A007304 multiplicity=distinct factor_count=3
       # OEIS-Catalogue: A046386 multiplicity=distinct factor_count=4
       # OEIS-Catalogue: A046387 multiplicity=distinct factor_count=5
       # OEIS-Catalogue: A067885 multiplicity=distinct factor_count=6
       # OEIS-Catalogue: A123321 multiplicity=distinct factor_count=7
       # OEIS-Catalogue: A123322 multiplicity=distinct factor_count=8
       # OEIS-Catalogue: A115343 multiplicity=distinct factor_count=9
     ],
    );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'multiplicity'}}->[$self->{'factor_count'}];
}

sub values_min {
  my ($self) = @_;
  my $factor_count = $self->{'factor_count'};
  if ($self->{'multiplicity'} eq 'distinct') {
    return Math::NumSeq::Primorials->ith($factor_count);
  } else {
    return 2 ** $factor_count;
  }
}

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'done'} = 1;
  $self->{'hi'} = 0;
  $self->{'pending'} = [];
}

sub next {
  my ($self) = @_;

  my $done = $self->{'done'};
  my $pending = $self->{'pending'};

  for (;;) {
    ### $done
    if (@$pending) {
      ### ret: $self->{'i'}, $pending->[0]
      return ($self->{'i'}++,
              ($self->{'done'} = shift @$pending));
    }

    ### refill pending array ...

    my $factor_count = $self->{'factor_count'};
    my $distinct = ($self->{'multiplicity'} eq 'distinct');
    ### $factor_count
    ### $distinct

    my $hi = $self->{'hi'} = ($self->{'hi'} == 0
                              ? 500 + $self->values_min
                              : $self->{'hi'} * 2);
    my $primes_hi
      = int ($hi / ($distinct
                    ? Math::NumSeq::Primorials->ith($factor_count-1)
                    : 2 ** ($factor_count-1)));
    ### $hi
    ### $primes_hi

    require Math::NumSeq::Primes;
    my @primes = Math::NumSeq::Primes::_primes_list (0, $primes_hi);
    if (@primes < ($distinct ? $factor_count : 1)) {
      ### not enough primes, go bigger ...
      next;
    }
    ### primes count: scalar(@primes)


    # This is an iterative array based descent so as not to hit the "deep
    # recursion" warnings if factor_count is 100 or more.  Though quite how
    # well such a large count works in practice is another matter.  Ought to
    # break out bignums for 2^100 etc to keep accuracy.
    #
    # The @any flags track whether any products were added by the descent.
    # It allows big chunks of the descent to be pruned back at a low depth
    # when the products get close to $hi.

    my @prod = (1);
    my @upto = (-1);
    my @any;

    my $depth = 0;
  OUTER: for (;;) {
      my $prod = $prod[$depth];
      if ($depth >= $factor_count-1) {
        ### lowest level: "prod=$prod and ".($upto[$depth]+1)." to $#primes"
        my $prev_len = @$pending;
        foreach my $i ($upto[$depth]+1 .. $#primes) {
          my $new_prod = $prod * $primes[$i];
          ### $new_prod
          if ($new_prod > $hi) {
            last;
          }
          if ($new_prod > $done) {
            push @$pending, $new_prod;
          }
        }
        ### pushed: "was $prev_len  count ".(@$pending-$prev_len)."  ".((@$pending>$prev_len) && $pending->[$prev_len])." to ".((@$pending>$prev_len) && $pending->[-1])
        ### pending: @$pending

        if ($depth > 0) {
          $any[$depth] ||= (@$pending != $prev_len);
        }

      } else {
        ### increment at: "depth=$depth"
        my $upto = ++$upto[$depth];
        if ($upto <= $#primes) {
          $prod *= $primes[$upto];
          if ($prod < $hi) {
            ### descend to: "upto=".($upto+$distinct)." prod=$prod"
            $depth++;
            $prod[$depth] = $prod;
            $upto[$depth] = $upto + $distinct - 1;
            $any[$depth] = 0;
            next;
          }
        }
      }

      ### backtrack ...
      for (;;) {
        if (--$depth < 0) {
          last OUTER;
        }
        $any[$depth] ||= $any[$depth+1];
        if ($any[$depth]) {
          ### continue at this depth ...
          last;
        } else {
          ### not any, backtrack further ...
        }
      }
    }


    # my $descend;
    # $descend = sub {
    #   my ($prod, $start, $depth) = @_;
    #   ### descend: "$prod $start $depth"
    #   my $any = 0;
    #   if ($depth > 0) {
    #     foreach my $i ($start .. $#primes) {
    #       my $new_prod = $prod * $primes[$i];
    #       if ($new_prod > $hi) {
    #         last;
    #       }
    #       if (! &$descend ($new_prod,
    #                        $distinct ? $i+1 : $i,
    #                        $depth-1)) {
    #         ### nothing added, break out ...
    #         last;
    #       }
    #       $any = 1;
    #     }
    #   } else {
    #     foreach my $i ($start .. $#primes) {
    #       my $new_prod = $prod * $primes[$i];
    #       if ($new_prod > $hi) {
    #         last;
    #       }
    #       $any = 1;
    #       if ($new_prod > $done) {
    #         push @$pending, $new_prod;
    #       }
    #     }
    #   }
    #   ### $any
    #   return $any;
    # };
    # &$descend (1, 0, $factor_count-1);


    @$pending = sort {$a<=>$b} @$pending;
  }
}

sub pred {
  my ($self, $value) = @_;
  ### AlmostPrimes pred(): $value

  unless ($value >= 0 && $value <= 0xFFFF_FFFF) {
    return undef;
  }
  if ($value < 1 || $value != int($value)) {
    return 0;
  }
  $value = "$value"; # numize Math::BigInt for speed

  my $factor_count = $self->{'factor_count'};
  my $distinct = ($self->{'multiplicity'} eq 'distinct');

  my $seen_count = 0;

  unless ($value % 2) {
    ### even ...
    $value /= 2;
    $seen_count = 1;
    until ($value % 2) {
      $value /= 2;
      if ($seen_count++ > $factor_count || $distinct) {
        return 0;
      }
      ### $seen_count
    }
  }

  my $limit = int(sqrt($value));
  for (my $p = 3; $p <= $limit; $p += 2) {
    unless ($value % $p) {
      $value /= $p;
      if ($seen_count++ > $factor_count) {
        return 0;
      }
      until ($value % $p) {
        $value /= $p;
        if ($seen_count++ > $factor_count || $distinct) {
          return 0;
        }
      }

      $limit = int(sqrt($value));  # new smaller limit
    }
  }
  if ($value != 1) {
    $seen_count++;
  }
  ### final seen_count: $seen_count
  return ($seen_count == $factor_count);
}

1;
__END__


=for stopwords Ryde Math-NumSeq primorial eg ie semiprimes

=head1 NAME

Math::NumSeq::AlmostPrimes -- semiprimes and other fixed number of prime factors

=head1 SYNOPSIS

 use Math::NumSeq::AlmostPrimes;
 my $seq = Math::NumSeq::AlmostPrimes->new (factor_count => 2);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This sequence is various "almost prime" numbers.  These are numbers with a
given number of prime factors.  The default is 2 prime factors, which are
the semi-primes.  For example 15 because 15=3*5.

    4, 6, 9, 10, 14, 15, 21, 22, 25, 26, 33, 34, 35, ...
    # starting i=1

=head2 Factor Count

C<factor_count =E<gt> $c> controls how many prime factors are to be used.
1 would be the primes themselves (the same as L<Math::NumSeq::Primes>).  Or
for example factor count 4 is as follows.  60 is present because 60=2*2*3*5
has precisely 4 prime factors.

    # factor_count => 4
    16, 24, 36, 40, 54, 60, ...

The first number in the sequence is 2^factor_count, being prime factor 2
repeated factor_count many times.

=head2 Multiplicity

C<multiplicity =E<gt> 'distinct'> asks for products of distinct primes.  For
the default factor count 2 this means exclude squares like 4=2*2, which
leaves

    # multiplicity => 'distinct'
    6, 10, 14, 15, 21, ...

For other factor counts, multiplicity "distinct" eliminates any numbers with
repeated factors, leaving only square-free numbers.  For example factor
count 4 becomes

    # factor_count => 4, multiplicity => 'distinct'
    210, 330, 390, 462, 510, 546, ...

For multiplicity "distinct" the first value in the sequence is a primorial
(see L<Math::NumSeq::Primorials>), being the first C<factor_count> many
primes multiplied together.  For example 210 above is primorial 2*3*5*7.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::AlmostPrimes-E<gt>new ()>

=item C<$seq = Math::NumSeq::AlmostPrimes-E<gt>new (factor_count =E<gt> $integer, multiplicity =E<gt> $str)>

Create and return a new sequence object.  C<multiplicity> can be

    "repeated"  repeated primes allowed (the default)
    "distinct"  all primes must be distinct

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is an almost-prime, ie. it has exactly
C<factor_count> many prime factors, and if C<distinct> is true then all
those factors different.

This check requires factorizing C<$value> and in the current code a hard
limit of 2**32 is placed on values to be checked, in the interests of not
going into a near-infinite loop.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>,
L<Math::NumSeq::PrimeFactorCount>

L<Math::NumSeq::Primorials>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2018, 2019, 2020 Kevin Ryde

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
