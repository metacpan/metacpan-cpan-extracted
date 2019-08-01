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

package Math::NumSeq::ReverseAdd;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 73;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant i_start => 0;

use constant characteristic_integer => 1;
sub characteristic_increasing {
  my ($self) = @_;
  # any non-zero start always increases
  return ($self->{'start'} != 0);
}
sub values_min {
  my ($self) = @_;
  return $self->{'start'};
}
sub values_max {
  my ($self) = @_;
  # starting from zero never changes, otherwise unbounded
  return ($self->{'start'} ? undef : 0);
}

use Math::NumSeq::Base::Digits;
use constant parameter_info_array =>
  [
   {
    name    => 'start',
    display => Math::NumSeq::__('Start'),
    type    => 'integer',
    default => 1,
    minimum => 0,
    width   => 5,
    description => Math::NumSeq::__('Starting value for the sequence.'),
   },
   Math::NumSeq::Base::Digits->parameter_info_list(),
  ];

sub description {
  my ($self) = @_;
  my $ret = Math::NumSeq::__('Reverse-add sequence, reverse the digits and add.');
  if (ref $self) { # object method
    $ret .= "\nStarting from $self->{'start'}, in radix $self->{'radix'}.";
  }
  return $ret;
}

#------------------------------------------------------------------------------
my %oeis_anum;

# cf A058042 written out in binary
#    ~/OEIS/a058042.txt  on reaching binary palindromes
#    A033908 sort-add

$oeis_anum{'2'}->{'1'} = 'A035522';
$oeis_anum{'2'}->{'22'} = 'A061561';
$oeis_anum{'2'}->{'77'} = 'A075253';
$oeis_anum{'2'}->{'442'} = 'A075268';
$oeis_anum{'2'}->{'537'} = 'A077076';
$oeis_anum{'2'}->{'775'} = 'A077077';
# OEIS-Catalogue: A035522 radix=2 start=1
# OEIS-Catalogue: A061561 radix=2 start=22
# OEIS-Catalogue: A075253 radix=2 start=77
# OEIS-Catalogue: A075268 radix=2 start=442
# OEIS-Catalogue: A077076 radix=2 start=537
# OEIS-Catalogue: A077077 radix=2 start=775

$oeis_anum{'3'}->{'1'} = 'A035523';
# OEIS-Catalogue: A035523 radix=3 start=1

$oeis_anum{'4'}->{'1'} = 'A035524';
$oeis_anum{'4'}->{'290'} = 'A075299';
$oeis_anum{'4'}->{'318'} = 'A075153';
$oeis_anum{'4'}->{'266718'} = 'A075466';
$oeis_anum{'4'}->{'270798'} = 'A075467';
$oeis_anum{'4'}->{'1059774'} = 'A076247';
$oeis_anum{'4'}->{'1059831'} = 'A076248';
# OEIS-Catalogue: A035524 radix=4 start=1
# OEIS-Catalogue: A075299 radix=4 start=290
# OEIS-Catalogue: A075153 radix=4 start=318
# OEIS-Catalogue: A075466 radix=4 start=266718
# OEIS-Catalogue: A075467 radix=4 start=270798
# OEIS-Catalogue: A076247 radix=4 start=1059774
# OEIS-Catalogue: A076248 radix=4 start=1059831

$oeis_anum{'10'}->{'1'} = 'A001127';
$oeis_anum{'10'}->{'3'} = 'A033648';
$oeis_anum{'10'}->{'5'} = 'A033649';
$oeis_anum{'10'}->{'7'} = 'A033650';
$oeis_anum{'10'}->{'9'} = 'A033651';
$oeis_anum{'10'}->{'89'} = 'A033670';
$oeis_anum{'10'}->{'196'} = 'A006960';
# OEIS-Catalogue: A001127 start=1
# OEIS-Catalogue: A033648 start=3
# OEIS-Catalogue: A033649 start=5
# OEIS-Catalogue: A033650 start=7
# OEIS-Catalogue: A033651 start=9
# OEIS-Catalogue: A033670 start=89
# OEIS-Catalogue: A006960 start=196

sub oeis_anum {
  my ($self) = @_;
  my $start = $self->{'start'};

  if ($start == 0) { return 'A000004'; } # all zeros
  # some sample zeros to exercise
  # OEIS-Other: A000004 radix=2 start=0
  # OEIS-Other: A000004 radix=9 start=0

  return $oeis_anum{$self->{'radix'}}->{$start};
}

#------------------------------------------------------------------------------

my $max = do {
  my $m = 1;
  foreach (1 .. 256) {
    my $double = 2*$m;
    my $next = 2*$m + 1;
    if ($next <= 2*$m || $next >= 2*$m+2) {
      last;
    }
    # must be able to divide for _reverse_in_radix()
    if (int($next/2) != $m) {
      last;
    }
    $m = $next;
  }
  $m = int($m/2);
  ### $m
  ### m hex: sprintf '%X', $m
  $m
};

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'value'} = $self->{'start'};
  $self->{'uv_limit'} = int ($max / $self->{'radix'});
}
sub next {
  my ($self) = @_;
  ### ReverseAdd next(): "i=$self->{'i'}  ".(ref $self->{'value'})." $self->{'value'}"
  ### reverse: _reverse_in_radix($self->{'value'}, $self->{'radix'})

  my $ret = $self->{'value'};
  if (! ref $ret && $ret >= $self->{'uv_limit'}) {
    ### go to bigint ...
    $self->{'value'} = Math::NumSeq::_to_bigint($ret);
  }
  $self->{'value'} += _reverse_in_radix($ret, $self->{'radix'});
  return ($self->{'i'}++,
          $ret);
}

sub ith {
  my ($self, $i) = @_;
  ### ReverseAdd ith(): $i

  if (_is_infinite($i)) {
    return undef;
  }

  my $radix = $self->{'radix'};
  my $start = $self->{'start'} || return 0;  # start 0 gives 0
  my $value = ($i*0) + $start;  # inherit bignum from $i

  while ($i-- > 0) {
    $value += _reverse_in_radix($value, $radix);
  }
  return $value;
}
# if ($value >= $self->{'uv_limit'}) {
#   ### go to bigint ...
#   $value = Math::NumSeq::_to_bigint($value);
#   while ($i-- > 0) {
#     $value += _reverse_in_radix($value, $radix);
#   }
#   last;
# }

sub pred {
  my ($self, $value) = @_;
  ### ReverseAdd pred(): $value

  my $start = $self->{'start'} || return ($value == 0);  # start 0 gives 0
  if ($value < $start || _is_infinite($value)) {
    return 0;
  }

  {
    my $int = int($value);
    if ($value != $int) {
      return 0;
    }
    $value = $int;
  }

  my $radix = $self->{'radix'};
  my $k = ($value*0) + $start;
  while ($k < $self->{'uv_limit'}) {
    unless ($value > $k) {
      return ($value == $k);
    }
    $k += _reverse_in_radix($k, $radix);
  }

  ### go to bigint ...
  for (;;) {
    unless ($value > $k) {
      return ($value == $k);
    }
    $k += _reverse_in_radix($k, $radix);
  }
}

# if ($value >= $self->{'uv_limit'}) {
#   ### go to bigint ...
#   $value = Math::NumSeq::_to_bigint($value);
#   while ($i-- > 0) {
#     $value += _reverse_in_radix($value, $radix);
#   }
#   last;
# }

# FIXME: smaller than this
sub value_to_i_estimate {
  my ($self, $value) = @_;
  if (_is_infinite($value)) {
    return $value;
  }
  my $i = 1;
  for (;; $i++) {
    $value = int($value/2);
    if ($value <= 1) {
      return $i;
    }
  }
}

my %binary_to_base4 = (# '0b' => '',
                       '00' => '0',
                       '01' => '1',
                       '10' => '2',
                       '11' => '3');
sub _bigint_as_base4 {
  my ($big) = @_;
  my $str = $big->as_bin;
  $str =~ s/^0b//;
  if (length($str) & 1) {
    $str = "0$str";
  }
  $str =~ s/(..)/$binary_to_base4{$1}/ge;
  return $str;
}
my @base4_to_binary = ('00','01','10','11');
sub _bigint_from_base4 {
  my ($class, $str) = @_;
  ### _bigint_from_base4(): $str
  $str =~ s/(.)/$base4_to_binary[$1]/ge;
  return $class->from_bin("0b$str");
}

sub _bigint_from_bin_with_0b {
}

my @radix_to_stringize_method;
my @string_to_bigint_method;
my $bigint = Math::NumSeq::_bigint();
{
  if ($bigint->can('as_bin') && $bigint->can('from_bin')) {
    $radix_to_stringize_method[2] = 'as_bin';
    # in past BigInt must have 0b prefix for from_bin()
    $string_to_bigint_method[2]
      = ($bigint->from_bin('0') == 0
         ? 'from_bin'
         : sub {
           ### from_bin with 0b: "0b$_[1]"
           $_[0]->from_bin("0b$_[1]");
         });

    $radix_to_stringize_method[4] = \&_bigint_as_base4;
    $string_to_bigint_method[4] = \&_bigint_from_base4;
  }
  if ($bigint->can('as_oct') && $bigint->can('from_oct')) {
    $radix_to_stringize_method[8] = 'as_oct';
    $string_to_bigint_method[8] = 'from_oct';
  }
  if ($bigint->can('as_hex') && $bigint->can('from_hex')) {
    $radix_to_stringize_method[16] = 'as_hex';
    # in past BigInt must have 0x prefix for from_hex()
    $string_to_bigint_method[16]
      = ($bigint->from_hex('0') == 0
         ? 'from_hex'
         : sub {
           ### from_hex with 0x: "0x$_[1]"
           $_[0]->from_hex("0x$_[1]");
         });
  }
  if ($bigint->can('bstr')) {
    $radix_to_stringize_method[10] = 'bstr';
    $string_to_bigint_method[10] = 'new';
  }
}
### @radix_to_stringize_method
### @string_to_bigint_method

# return $n reversed in $radix
sub _reverse_in_radix {
  my ($n, $radix) = @_;

  # prefer bstr() over plain stringize "$n" since BigInt in 5.8 and 5.10
  # seems to do something dubious in "$n" which rounds off
  if (ref $n
      && $n->isa('Math::BigInt')
      && (my $method = $radix_to_stringize_method[$radix])) {
    my $from = $string_to_bigint_method[$radix];
    my $str = $n->$method();
    $str =~ s/^0[bx]?//;
    ### $str
    ### $from
    ### reverse: scalar(reverse($str))
    ### result: $bigint->$from(scalar(reverse($str))).''
    return $bigint->$from(scalar(reverse($str)));
  }

  if ($radix == 10) {
    return scalar(reverse("$n"));
  }

  # ### _reverse_in_radix(): sprintf '%#X %d', $n, $n

  my $ret = $n*0;   # inherit bignum 0
  do {
    $ret = $ret * $radix + ($n % $radix);
  } while ($n = int($n/$radix));

  # ### ret: sprintf '%#X %d', $ret, $ret
  return $ret;
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::ReverseAdd -- steps of the reverse-add algorithm

=head1 SYNOPSIS

 use Math::NumSeq::ReverseAdd;
 my $seq = Math::NumSeq::ReverseAdd->new (start => 196);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The reverse-add sequence from a given starting point.  The digit reversal of
a given value is added to make the next.  For example C<start =E<gt> 1>,

    1,2,4,8,16,77,154,605,1111,2222,...

At 16 the reversal is 61, adding those 16+61=77 is the next value.  There's
some interest in whether a palindrome like 77 is ever reached in the
sequence, but the sequence here continues on forever.

The default is digits reversed in decimal, but the C<radix> parameter can
select another base.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::ReverseAdd-E<gt>new (start =E<gt> $n)>

=item C<$seq = Math::NumSeq::ReverseAdd-E<gt>new (start =E<gt> $n, radix =E<gt> $r)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>th value in the sequence.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::ReverseAddSteps>

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
