# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::RepdigitAny;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq 7; # v.7 for _is_infinite()
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Repdigit Any Radix');
use constant description => Math::NumSeq::__('Numbers which are a "repdigit" like 1111, 222, 999 etc of 3 or more digits in some number base.');
use constant i_start => 1;
use constant values_min => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

# cf A167783 - length >=2, 2 or more bases
#    A053696 - length >=3, 1 or more bases repunit
#
#    A158235 - square is a repdigit in some base < i
#    A158236 - the radix for those squares
#    A158237 - those squares, ie. squares which are repdigits some base
#    A158245 - "primitives" in squares seq, meaning square-free
#
use constant oeis_anum => 'A167782'; # length >=3, 1 or more bases

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'done'} = 0;
  $self->{'ones'}   = [ undef, undef, 7 ];
  $self->{'digits'} = [ undef, undef, 1 ];
}

sub next {
  my ($self) = @_;
  ### RepdigitAny next(): $self->{'i'}

  my $done;
  if ($done = $self->{'done'}) {
    my $min = $done*$done + 7;
    my $ones = $self->{'ones'};
    my $digits = $self->{'digits'};

    for (my $radix = 2; ; $radix++) {
      ### $radix

      my $one;
      if ($radix > $#$ones) {
        ### maybe extend array: $radix
        $one = ($radix + 1) * $radix + 1;
        if ($one > $min) {
          ### stop at big one: $one
          last;
        }
        $ones->[$radix] = $one;
        $digits->[$radix] = 1;
      } else {
        $one = $ones->[$radix];
      }

      my $repdigit;
      while (($repdigit = $one * $digits->[$radix]) <= $done) {
        ### increase past done: $repdigit
        if (++$digits->[$radix] >= $radix) {
          $digits->[$radix] = 1;
          $one = $ones->[$radix] = $ones->[$radix] * $radix + 1;
          ### digit wrap new ones: $ones->[$radix]
        } else {
          ### digit step: $digits->[$radix]
        }
      }

      ### consider repdigit: $repdigit
      if ($repdigit < $min) {
        ### min now: "$repdigit at $radix"
        $min = $repdigit;
      }
    }
    ### result: $min
    $self->{'done'} = $min;
    return ($self->{'i'}++, $min);

  } else {
    # special case value 0
    $self->{'done'} = 1;
    return ($self->{'i'}++, 0);
  }
}

sub pred {
  my ($self, $value) = @_;
  ### RepdigitAny pred(): $value

  if ($value == 0) {
    return 1;
  }
  if (_is_infinite($value) || $value != int($value)) {
    return 0;
  }

 RADIX: for (my $radix = 2; ; $radix++) {
    my $ones = ($radix + 1) * $radix + 1;
    if ($ones > $value) {
      return 0;
    }

    do {
      if ($ones == $value) {
        return 1;
      }
      foreach my $digit (2 .. $radix-1) {
        my $repdigit = $digit * $ones;
        if ($repdigit == $value) {
          return 1;
        }
        if ($repdigit > $value) {
          next RADIX;
        }
      }
      $ones = $ones * $radix + 1;
    } while ($ones <= $value);
  }
}

1;
__END__

# b^2 + b + 1 = k
# (b+0.5)^2 + .75 = k
# (b+0.5)^2 = (k-0.75)
# b = sqrt(k-0.75)-0.5;
#  1+int(sqrt($hi-0.75))) {
#
# sub new {
#   my ($class, %options) = @_;
#   my $lo = $options{'lo'} || 0;
#   my $hi = $options{'hi'};
# 
#   ### bases to: 2+int(sqrt($hi-0.75))
#   my %ret = (0 => 1); # zero considered 000...
#   foreach my $base (2 .. 1+int(sqrt($hi-0.75))) {
#     my $n = ($base + 1) * $base + 1;  # 111 in $base
#     while ($n <= $hi) {
#       $ret{$n} = 1;
#       foreach my $digit (2 .. $base-1) {
#         if ((my $mult = $digit * $n) <= $hi) {
#           $ret{$mult} = 1;
#         }
#       }
#       $n = $n * $base + 1;
#     }
#   }
#   return $class->SUPER::new (%options,
#                              array => [ sort {$a <=> $b} keys %ret ]);
# }

  #   require Math::Prime::XS;
  #   my @upto;
  #   my $i = 1;
  #   my @primes = Math::Prime::XS::sieve_primes ($maxbase);
  #   return sub {
  #     for (;;) {
  #       $i++;
  #       my $base_limit = 1+int(sqrt($i/2));
  #       foreach my $base (@primes) {
  #         last if ($base > $base_limit);
  #         foreach my $digit (@primes) {
  #           last if ($digit >= $base);
  #           my $ref = \$upto[$base]->[$digit];
  #           $$ref ||= (($base * $digit) + $digit) * $base + $digit;
  #           while ($$ref < $i) {
  #             $$ref = $$ref * $base + $digit;
  #           }
  #           if ($$ref == $i) {
  #             return $i;
  #           }
  #         }
  #       }
  #     }
  #   };


=for stopwords Ryde Math-NumSeq repdigit repdigits radix radices

=head1 NAME

Math::NumSeq::RepdigitAny -- numbers which are a repdigit in any radix

=head1 SYNOPSIS

 use Math::NumSeq::RepdigitAny;
 my $seq = Math::NumSeq::RepdigitAny->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The numbers 0, 7, 13, 15, 21, 26, 31, etc which are a repdigit of 3 or more
digits in any radix.  For example 7 is 111 base 2, 26 is 222 base 3, 31 is
11111 base 2, etc.  Effectively this is the union of the Repdigits sequence
for all radices.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::RepdigitAny-E<gt>new ()>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a repdigit of 3 or more digits in some radix.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Repdigits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
