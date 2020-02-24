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


# http://mathworld.wolfram.com/UndulatingNumber.html

package Math::NumSeq::UndulatingNumbers;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('Undulating Numbers');
use constant description => Math::NumSeq::__('Numbers like 37373 which are a pattern of digits ABAB...');
use constant default_i_start => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant values_min => 0;

use Math::NumSeq::Base::Digits;
use constant parameter_info_array =>
  [
   Math::NumSeq::Base::Digits::parameter_common_radix(),
   { name        => 'including_repdigits',
     type        => 'boolean',
     display     => Math::NumSeq::__('Repdigits'),
     default     => 1,
     description => Math::NumSeq::__('Whether to include repdigits A=B.'),
   },
  ];

#------------------------------------------------------------------------------

# cf A046075 - decimal A!=B and min length 3
#    A033619 - decimal A=B any length
#
#    A046076 - "binary undulants", numbers k where 2^k written in decimal
#              has an 010 or 101 somewhere
#    
my @oeis_anum;

$oeis_anum[1]->[2]  = 'A000975'; # binary A!=B no consecutive equal bits
# OEIS-Catalogue: A000975 radix=2 including_repdigits=0

# $oeis_anum[0]->[10] = 'A033619'; # decimal incl A=B, but OFFSET=1 value=0
# # OEIS-Catalogue: A033619 including_repdigits=1

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[!$self->{'including_repdigits'}]->[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  my $radix = $self->{'radix'};
  if ($radix < 2) { $radix = 10; }
  $self->{'radix'} = $radix;

  $self->{'i'}        = 0;
  $self->{'value'}    = -1;
  $self->{'inc'}      = 1;   # 10101010 or 101010101
  $self->{'inc_even'} = 0;   # 1 if inc=10101010 or 0 if inc=101010101
  $self->{'a'}        = 0;   # 1 to 9, or 0 for initial smalls
  $self->{'b'}        = 0;   # 0 to 9, perhaps skipping a==b
}

sub next {
  my ($self) = @_;
  ### UndulatingNumbers next() ...
  ### inc: $self->{'inc'}
  ### value: $self->{'value'}

  my $radix = $self->{'radix'};
  my $value;
  if ($value = ($self->{'value'} += $self->{'inc'})) {
    $self->{'b'}++;
    ### value: $self->{'value'}
    ### a: $self->{'a'}
    ### b: $self->{'b'}

    if (! $self->{'including_repdigits'}
        && $self->{'b'} == $self->{'a'}) {
      $self->{'value'} = ($value += $self->{'inc'});
      $self->{'b'}++;

      ### no repdigits, skip a==b to new b: $self->{'b'}
      ### value now: $value
    }

    if ($self->{'b'} >= $radix ) {
      ### b overflow, a inc ...
      ### inc_even: $self->{'inc_even'}

      # a9a + 10 -> (a+1)0(a)
      # if inc=10..10 ends in 0 then need 1 extra to give (a+1)0(a+1)

      $self->{'b'} = 0;
      $self->{'value'} = ($value += $self->{'inc_even'});
      ### value now: $value

      if (++$self->{'a'} >= $radix) {
        ### a overflow, next length ...

        # inc=101 -> 1010    inc_even=0
        # or 1010 -> 10101   inc_even=0
        my $inc_even = ($self->{'inc_even'} ^= 1);
        $self->{'inc'} = $self->{'inc'} * $radix + !$inc_even;
        $self->{'a'} = 1;
        $self->{'value'} = ($value += $inc_even);

        ### lengthen to inc: $self->{'inc'}
        ### n now: $value
      }
    }
  }
  return ($self->{'i'}++, $value);
}

# A is 0 to 9 = 10 values
# AB is 10 to 99 = 90 values
# total R*R
# then high AB is 10 to 99 = 90 values
# total 90 = (R-1)*R
# R=2 total 2*2-1=3 1,10,11
#
# or without repdigits
# AB skips 11, ..., 99 = 10 values
# total R*R - R = R*(R-1)
#
sub ith {
  my ($self, $i) = @_;
  ### UndulatingNumbers ith(): $i
  my $radix = $self->{'radix'};
  my $rdec = $radix - 1;

  if ($i < 0) {
    return undef;
  }

  my $including_repdigits = $self->{'including_repdigits'};

  my $pair_step = ($including_repdigits ? $radix*$radix : $radix*$rdec+1);
  ### small pair_step: $pair_step

  if ($i < $pair_step || _is_infinite($i)) {
    ### below small pairs ...

    # at i=11 skip to value=12
    #    i=19         value=20
    #    i=20         value=21
    #    i=21 skip to value=23
    #
    if (! $including_repdigits && $i > $radix) {
      $i += int(($i-1)/$radix); # skip 11,22,33 etc
    }
    return $i;
  }

  $i -= $pair_step;
  ### i remainder: $i

  $pair_step = $rdec*($including_repdigits ? $radix : $rdec);
  ### decreased pair_step: $pair_step

  my $i_pair = $i % $pair_step;
  my $i_len = int($i/$pair_step);
  ### $i_pair
  ### $i_len

  my ($a, $b);
  if ($including_repdigits) {
    $a = int($i_pair/$radix) + 1;
    $b = $i_pair % $radix;
  } else {
    $a = int($i_pair/$rdec) + 1;
    $b = $i_pair % $rdec;
    $b += ($b >= $a);
  }
  ### $a
  ### $b

  my $ret = $a*$radix + $b;
  ### $ret
  while ($i_len-- >= 0) {
    $ret = ($ret * $radix) + $a;
    ### append A to: $ret

    last unless $i_len-- >= 0;
    $ret = ($ret * $radix) + $b;
    ### append B to: $ret
  }

  ### $ret
  return $ret;
}

sub pred {
  my ($self, $value) = @_;

  if (_is_infinite($value)) {
    return undef;
  }
  if ($value != int($value)) {
    return 0;
  }

  my $radix = $self->{'radix'};
  my $a = $value % $radix;
  if ($value = int($value/$radix)) {
    my $b = $value % $radix;
    if (! $self->{'including_repdigits'}
        && $a == $b) {
      return 0;
    }

    while ($value = int($value/$radix)) {
      if (($value % $radix) != $a) { return 0; }

      $value = int($value/$radix) || last;
      if (($value % $radix) != $b) { return 0; }
    }
  }
  return 1;
}

sub value_to_i_floor {
  my ($self, $value) = @_;
  ### value_to_i_floor(): $value

  if ($value <= 0) {
    return 0;
  }
  if (_is_infinite($value)) {
    return $value;
  }

  my $radix = $self->{'radix'};
  my @digits = _digit_split(int($value), $radix);

  my $a = pop @digits;
  @digits or return $a;  # one digit only

  my $including_repdigits = $self->{'including_repdigits'};
  my $rdec = $radix - 1;

  my $b = pop @digits;
  ### $a
  ### $b
  ### $including_repdigits
  ### digit count: scalar(@digits)
  ### $radix
  ### $rdec

  my $i = $a * ($including_repdigits ? $radix : $rdec) + $b
    + ($including_repdigits || $a < $b ? 0 : 1)
    + scalar(@digits) * $rdec*($including_repdigits ? $radix : $rdec);
  ### $i

  # see if the value is in fact smaller than ABABAB...
  # if !repdigits and have a=b then it's bigger

  if (! $including_repdigits && $a == $b) {
    ### repdigits when a=b ...
    return $i-1;
  }

  if ($including_repdigits
      || $a != $b) {

    while (@digits) {
      if ((my $c = pop @digits) != $a) {  # found different than ABABAB...
        if ($c < $a) { $i -= 1; }
        return $i;
      }
      ($a,$b) = ($b,$a);
    }
  }
  # value is either ABAB exactly, or something bigger
  return $i;
}
*value_to_i_estimate = \&value_to_i_floor;


sub _digit_split {
  my ($n, $radix) = @_;
  ### _digit_split(): $n
  my @ret;
  while ($n) {
    push @ret, $n % $radix;
    $n = int($n/$radix);
  }
  return @ret;   # low to high
}

1;
__END__


  # if ($radix == 10) {
  #   return (length($n) <= 1
  #           || (substr($n,0,1) ne substr($n,1,1)
  #               && $n =~ /^(([0-9])[0-9])\1*\2?$/));
  # }

  # if (0 && $radix == 10) {
  #   return bless { i     => -11,
  #                  rep   => 0,
  #                  radix => $radix,
  #                }, $class;
  # } else {
  # }

# my @table =
#   grep {pred({radix=>10},$_)}
#   map {sprintf '%02d', $_}
#   10 .. 999;

  # my $rep = $self->{'rep'};
  # if (0 && $radix == 10) {
  #   my $i = ++$self->{'i'};
  #   if ($i < 0) {
  #     return $i+10;
  #   }
  #   if ($i > $#table) {
  #     $i = $self->{'i'} = $self->i_start;
  #     $self->{'rep'} = ++$rep;
  #   }
  #   my $ret = $table[$i];
  #   return $ret . (substr($ret,-2) x $rep);
  #
  # } else {

                   # limit => $radix * $radix - 1,
                   # skip  => $radix+1,  # at 11

    # if ($n >= $self->{'limit'}) {
    #   $n = ($self->{'value'} += $self->{'inc'} + 1);
    #   $self->{'limit'} = ($self->{'limit'} + $radix * $self->{'inc'});
    #   $self->{'skip'} = $radix - 1;
    #   ### limit, skip to: $n
    #   ### inc now: $self->{'inc'}
    #   ### next limit: $self->{'limit'}
    #
    # } elsif (--$self->{'skip'} < 0) {
    #   $n = ($self->{'value'} += $self->{'inc'});
    #   $self->{'skip'} = $radix - 1;
    #   ### skip to: $n
    # }


=for stopwords Ryde Math-NumSeq ie ABABAB radix

=head1 NAME

Math::NumSeq::UndulatingNumbers -- numbers with alternating digits ABABAB...

=head1 SYNOPSIS

 use Math::NumSeq::UndulatingNumbers;
 my $seq = Math::NumSeq::UndulatingNumbers->new (radix => 10);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the sequence of numbers with digits ABABAB... alternating between
two values,

    0 ... 99,
    101, 111, 121, 131, ... 191,
    202, 212, 222, 232, ... 292,
    ...
    909, 919, 929, 939, ... 999,
    1010, 1111, 1212, ... 1919,
    ...

Numbers with just 1 or 2 digits are A or AB and are considered of undulating
form.  This means all numbers up to 99 are undulating.

The default is decimal or the optional C<radix=E<gt>$r> can select another
radix.

In binary the only two digits are 0 and 1 and the high digit must be 1, so
it ens up being just 101... and 111...

    0, 1, 10, 11, 101, 111, 1010, 1111, 10101, 11111, ...
    (in binary)

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::UndulatingNumbers-E<gt>new ()>

=item C<$seq = Math::NumSeq::UndulatingNumbers-E<gt>new (radix =E<gt> $r)>

Create and return a new sequence object.  The default radix is 10.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is an undulating number, ie. has digits of the form
ABABAB...

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return the i for the undulating number E<lt>= $value.

=back

=head1 SEE ALSO

L<Math::NumSeq>

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
