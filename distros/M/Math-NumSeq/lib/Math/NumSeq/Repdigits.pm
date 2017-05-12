# Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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

package Math::NumSeq::Repdigits;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

use Math::NumSeq::NumAronson 8; # new in v.8
*_round_down_pow = \&Math::NumSeq::NumAronson::_round_down_pow;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Repdigits');
use constant description => Math::NumSeq::__('Numbers which are a "repdigit", meaning 0, 1 ... 9, 11, 22, 33, ... 99, 111, 222, 333, ..., 999, etc.  The default is decimal, or select a radix.');
use constant i_start => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant values_min => 0;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

#------------------------------------------------------------------------------
# cf A002275 - repunits
#    A108850 - repunits count of 1 bits

my @oeis_anum = (
                 # OEIS-Catalogue array begin
                 undef,     # 0
                 undef,     # 1
                 'A000225', # radix=2  # 2^i-1
                 'A048328', # radix=3
                 'A048329', # radix=4
                 undef,     # A048330 starts OFFSET=1 value=0
                 'A048331', # radix=6
                 'A048332', # radix=7
                 undef,     # A048333 starts OFFSET=1 value=0
                 'A048334', # radix=9 
                 'A010785', # radix=10  # starting from OFFSET=0 value=0
                 'A048335', # radix=11
                 'A048336', # radix=12
                 'A048337', # radix=13
                 'A048338', # radix=14
                 'A048339', # radix=15
                 'A048340', # radix=16
                 # OEIS-Catalogue array end
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  my $radix = $self->{'radix'};
  if ($radix < 2) {
    $radix = $self->{'radix'} = 10;
  }

  $self->{'i'} = $self->i_start;
  $self->{'n'} = -1;
  if ($radix != 2) {
    $self->{'inc'} = 1;
    $self->{'digit'} = -1;
  }
}
sub _UNTESTED__seek_to_i {
  my ($self, $i) = @_;
  $self->{'i'} = $i;
  my $radix = $self->{'radix'};
  if ($radix == 2) {
    if ($i == 0) {
      $self->{'n'} = -1;
    } else {
      $self->{'n'} = $self->ith($i-1);
    }
  } else {
    my $digit = $self->{'digit'} = ($i % $radix) - 1;
    my $exp = int($i/$radix);
    $self->{'inc'} = $self->ith($i-$digit);
    $self->{'n'} = $self->{'inc'} * $digit;
  }
}
sub _UNTESTED__seek_to_value {
  my ($self, $value) = @_;
  $self->seek_to_i($self->value_to_i_ceil($value));
}

sub next {
  my ($self) = @_;

  my $i = $self->{'i'}++;
  my $radix = $self->{'radix'};
  if ($radix == 2) {
    if ($i == 31) {
      $self->{'n'} = _to_bigint($self->{'n'});
    }
    if ($i) {
      $self->{'n'} *= 2;
    }
    return ($i, $self->{'n'} += 1);

  } else {
    # ENHANCE-ME: automatic promote to bigint

    my $n = ($self->{'n'} += $self->{'inc'});
    if (++$self->{'digit'} >= $radix) {
      $self->{'inc'} = $self->{'inc'} * $radix + 1;
      $self->{'digit'} = 1;
      $self->{'n'} = ($n += 1); # not ++$n as that gives warnings on overflow
      ### digit: $self->{'digit'}
      ### inc: $self->{'inc'}
      ### $n
    }
    return ($i, $n);
  }
}

sub ith {
  my ($self, $i) = @_;
  my $radix = $self->{'radix'};

  if (_is_infinite ($i)) {
    return $i;
  }

  if ($radix == 2) {
    my $one = ($i >= 31 ? _to_bigint(1) : 1);
    return ($one << $i) - 1;
  }

  if (($i-=1) < 0) {
    return 0;
  }
  my $digit = ($i % ($radix-1)) + 1;
  $i = int($i/($radix-1)) + 1;
  return ($radix ** $i - 1) / ($radix - 1) * $digit;
}

sub pred {
  my ($self, $value) = @_;

  {
    my $int = int($value);
    if ($value != $int) {
      return 0;
    }
    $value = $int;  # prefer BigInt if input BigFloat
  }

  my $radix = $self->{'radix'};
  if ($radix == 2) {
    return ! (($value+1) & $value);

  }
  if ($radix == 10) {
    my $digit = substr($value,0,1);
    return ($value !~ /[^$digit]/);
  }

  my $digit = $value % $radix;
  while ($value = int($value/$radix)) {
    unless (($value % $radix) == $digit) { # false for inf or nan
      return 0;
    }
  }
  return 1;
}

sub value_to_i_ceil {
  my ($self, $value) = @_;
  ### value_to_i_ceil(): $value

  if (_is_infinite ($value)) {
    return $value;
  }
  if ($value <= 0) {
    return 0;
  }
  my $int = int($value);
  if ($value != $int) {
    $int += 1;
  }
  ### $int

  my $radix = $self->{'radix'};
  my @digits = _digit_split_lowtohigh($int, $radix)
    or return 0;  # if $value==0

  my $high_digit = pop @digits;
  my $i = $high_digit + ($radix-1) * scalar(@digits);
  ### $high_digit
  ### $i

  foreach my $digit (reverse @digits) { # high to low
    if ($digit > $high_digit) {
      return $i + 1;
    }
    if ($digit < $high_digit) {
      last;
    }
  }
  return $i;
}
sub value_to_i_floor {
  my ($self, $value) = @_;

  if ($value < 1) {
    return 0;
  }
  if (_is_infinite ($value)) {
    return $value;
  }
  $value = int($value);

  my $radix = $self->{'radix'};
  my @digits = _digit_split_lowtohigh($value, $radix)
    or return 0;  # if $value==0

  my $high_digit = pop @digits;
  my $i = $high_digit + ($radix-1) * scalar(@digits);

  foreach my $digit (reverse @digits) { # high to low
    if ($digit < $high_digit) {
      return $i - 1;
    }
  }
  return $i;
}

# either floor or 1 too big
sub value_to_i_estimate {
  my ($self, $value) = @_;
  ### value_to_i_estimate() ...

  if ($value < 1) {
    return 0;
  }
  if (_is_infinite ($value)) {
    return $value;
  }
  my $radix = $self->{'radix'};
  my ($power, $exp) = _round_down_pow ($value, $radix);
  return int($value/$power)  # high digit
    + ($radix-1) * $exp;
}

#------------------------------------------------------------------------------

{
  my %binary_to_base4 = ('00' => '0',
                         '01' => '1',
                         '10' => '2',
                         '11' => '3');
  my @radix_to_coderef;
  $radix_to_coderef[2] = sub {
    (my $str = $_[0]->as_bin) =~ s/^0b//;  # strip leading 0b
    return reverse split //, $str;
  };
  $radix_to_coderef[4] = sub {
    (my $str = $_[0]->as_bin) =~ s/^0b//; # strip leading 0b
    if (length($str) & 1) {
      $str = "0$str";
    }
    $str =~ s/(..)/$binary_to_base4{$1}/ge;
    return reverse split //, $str;
  };
  $radix_to_coderef[8] = sub {
    (my $str = $_[0]->as_oct) =~ s/^0//;  # strip leading 0
    return reverse split //, $str;
  };
  $radix_to_coderef[10] = sub {
    return reverse split //, $_[0]->bstr;
  };
  $radix_to_coderef[16] = sub {
    (my $str = $_[0]->as_hex) =~ s/^0x//;  # strip leading 0x
    return reverse map {hex} split //, $str;
  };

  sub _digit_split_lowtohigh {
    my ($n, $radix) = @_;
    ### _digit_split_lowtohigh(): $n

    $n || return; # don't return '0' from BigInt stringize

    if (ref $n
        && $n->isa('Math::BigInt')
        && (my $coderef = $radix_to_coderef[$radix])) {
      return $coderef->($_[0]);
    }

    my @ret;
    do {
      push @ret, $n % $radix;
    } while ($n = int($n/$radix));
    return @ret;   # array[0] low digit
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq repdigit repdigits

=head1 NAME

Math::NumSeq::Repdigits -- repdigits 11, 22, 33, etc

=head1 SYNOPSIS

 use Math::NumSeq::Repdigits;
 my $seq = Math::NumSeq::Repdigits->new (radix => 10);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The sequence of repdigit numbers,

    0, 1 ... 9, 11, 22, 33, ... 99, 111, 222, 333, ..., 999, etc
    starting i=0

comprising repetitions of a single digit.  The default is decimal or a
C<radix> parameter can be given.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Repdigits-E<gt>new ()>

=item C<$seq = Math::NumSeq::Repdigits-E<gt>new (radix =E<gt> $r)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th repdigit.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a repdigit in the given C<radix>.

=item C<$i = $seq-E<gt>value_to_i_ceil($value)>

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

Return the C<$i> index of C<$value>, rounding up or down if C<$value> is not
a repdigit.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::RepdigitAny>,
L<Math::NumSeq::Beastly>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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
