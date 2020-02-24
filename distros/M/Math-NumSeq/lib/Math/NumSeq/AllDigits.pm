# Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::AllDigits;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq::Base::Digits;
@ISA = ('Math::NumSeq::Base::Digits');

use Math::NumSeq 7; # v.7 for _is_infinite()
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('All Integer Digits');
use constant description => Math::NumSeq::__('Digits of all the integers.');
use constant default_i_start => 0;

use constant parameter_info_array =>
  [
   Math::NumSeq::Base::Digits->parameter_info_list,  # 'radix'
   {
    name        => 'order',
    share_key   => 'order_frs',
    type        => 'enum',
    default     => 'forward',
    choices     => ['forward','reverse','sorted'],
    choices_display => [Math::NumSeq::__('Forward'),
                        Math::NumSeq::__('Reverse'),
                        Math::NumSeq::__('Sorted'),
                       ],
    description => Math::NumSeq::__('Order for the digits within each integer.'),
   },
  ];

#------------------------------------------------------------------------------

# cf A030303 - base 2 positions of 1s, start 1
#    A030309 - positions of 0 in reverse
#    A030310 - positions of 1 in reverse
#    A030305 - base 2 lengths of runs of 0s
#    A030306 - base 2 lengths of runs of 1s
#    A058935 - base 2 concats as bignums
#
#    A054637 - base 3 partial sums digits, start i=0 value=0
#
#    A054632 - decimal partial sums
#
#    A136414 - decimal 2 digits at a time, start i=1 value=1
#    A193431 - decimal 3 digits at a time
#    A193492 - decimal 4 digits at a time
#    A193493 - decimal 5 digits at a time
#    A019519 - decimal concat odd nums as bignums
#    A000422 - decimal reverse concats as bignums
#
#    A031324 - decimal digits of Fibonacci numbers
#    A034004 - decimal digits of triangular numbers
#    A034005 - decimal digits of Catalan numbers
#
my %oeis_anum;

$oeis_anum{'forward'}->[0]->[2] = 'A030190'; # base 2, start i=0 value=0
$oeis_anum{'forward'}->[1]->[2] = 'A030302'; # base 2, start i=1 value=1
# OEIS-Catalogue: A030190 radix=2 i_start=0
# OEIS-Catalogue: A030302 radix=2 i_start=1
$oeis_anum{'reverse'}->[0]->[2] = 'A030308'; # base 2 LE start i=1 value=1
# OEIS-Catalogue: A030308 radix=2 order=reverse i_start=0

$oeis_anum{'forward'}->[0]->[3] = 'A054635'; # base 3, start i=0 value=0
$oeis_anum{'forward'}->[1]->[3] = 'A003137'; # base 3, start i=1 value=1
$oeis_anum{'reverse'}->[0]->[3] = 'A030341'; # base 3, start i=0 value=0
# OEIS-Catalogue: A054635 radix=3 i_start=0
# OEIS-Catalogue: A003137 radix=3 i_start=1
# OEIS-Catalogue: A030341 radix=3 order=reverse i_start=0

$oeis_anum{'forward'}->[1]->[4] = 'A030373'; # base 4, start i=1 value=1
$oeis_anum{'reverse'}->[0]->[4] = 'A030386'; # base 4, start i=0 value=0
# OEIS-Catalogue: A030373 radix=4 i_start=1
# OEIS-Catalogue: A030386 radix=4 order=reverse i_start=0

$oeis_anum{'forward'}->[1]->[5] = 'A031219'; # base 5, start i=1 value=1
$oeis_anum{'reverse'}->[0]->[5] = 'A031235'; # base 5, start i=0 value=0
# OEIS-Catalogue: A031219 radix=5 i_start=1
# OEIS-Catalogue: A031235 radix=5 order=reverse i_start=0

$oeis_anum{'reverse'}->[0]->[6] = 'A030567'; # base 6, start i=0 value=0
# OEIS-Catalogue: A030567 radix=6 order=reverse i_start=0

$oeis_anum{'forward'}->[0]->[7] = 'A030998'; # base 7, start i=0 value=0
$oeis_anum{'reverse'}->[1]->[7] = 'A031007'; # base 7 LE start i=1 value=1
# OEIS-Catalogue: A030998 radix=7 i_start=0
# OEIS-Catalogue: A031007 radix=7 order=reverse i_start=1

$oeis_anum{'forward'}->[0]->[8] = 'A054634'; # base 8, start i=0 value=0
$oeis_anum{'forward'}->[1]->[8] = 'A031035'; # base 8, start i=1 value=1
# OEIS-Catalogue: A054634 radix=8 i_start=0
# OEIS-Catalogue: A031035 radix=8 i_start=1
$oeis_anum{'reverse'}->[1]->[8] = 'A031045'; # base 8 LE start i=1 value=1
# OEIS-Catalogue: A031045 radix=8 order=reverse i_start=1

$oeis_anum{'forward'}->[1]->[9] = 'A031076'; # base 9, start i=1 value=1
# OEIS-Catalogue: A031076 radix=9 i_start=1
$oeis_anum{'reverse'}->[1]->[9] = 'A031087'; # base 9 LE start i=1 value=1
# OEIS-Catalogue: A031087 radix=9 order=reverse i_start=1

$oeis_anum{'forward'}->[1]->[10] = 'A007376'; # base 10, start i=1 value=1
# OEIS-Catalogue: A007376 i_start=1
$oeis_anum{'reverse'}->[1]->[10] = 'A031298'; # base 10 LE start i=1 value=1
# OEIS-Catalogue: A031298 radix=10 order=reverse i_start=1
#
# A033307 is the digits starting from 1 the same as A007376, but with
# offset=0 for that 1.

sub oeis_anum {
  my ($self) = @_;
  ### $self
  return $oeis_anum{$self->{'order'}}->[$self->i_start]->[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  my $i_start = $self->i_start;
  $self->{'n'} = $self->{'i'} = $i_start;
  $self->{'pending'} = [ $i_start ];
}
sub next {
  my ($self) = @_;
  ### AllDigits next(): $self->{'i'}

  my $value;
  unless (defined ($value = shift @{$self->{'pending'}})) {
    my $pending = $self->{'pending'};
    my $radix = $self->{'radix'};
    my $n = ++$self->{'n'};
    while ($n) {
      push @$pending, $n % $radix;
      $n = int($n/$radix);
    }
    my $order = $self->{'order'};
    if ($order eq 'forward') {
      @$pending = reverse @$pending;
    } elsif ($order eq 'sorted') {
      @$pending = sort {$a<=>$b} @$pending;
    }
    $value = shift @$pending;
  }
  return ($self->{'i'}++, $value);
}

# 1 to 9    r-1  of 1 digit
#           i=0 to i=9
# 10 to 99  r^2-r of 2 digits is 2*(r^2-r) values
#           total 2*r^2-2r+r = 2*r^2 - r
#           i=10 to i=10+2*(99-10+1)-1=189
# 100 to 999  r^3-r^2 of 3 digits is 3*(r^3-r^2) values
#           total 2*r^2 - r + 3*(r^3-r^2)
#               = 3*r^3 + 2*r^2 - r + -3*r^2
#               = 3*r^3 - r^2 - r
#           i=191 to ...
# 1000 to 9999  r^4-r^3 of 4 digits is  values
#           total 4*(r^4-r^3) + 3*r^3 - r^2 - r
#               = 4*r^4 - r^3 - r^2 - r
#
# i = k*r^k - (r^k-1)/(r-1)
#   = (k*(r-1)*r^k - r^k + 1) / (r-1)
#   = ((kr-k-1)*r^k + 1) / (r-1)
#
# ((kr-k-1)*r^k + 1)  = i*(r-1)
# (kr-k-1)*r^k  = i*(r-1)-1
#

sub ith {
  my ($self, $i) = @_;
  ### AllDigits ith(): "$i"
  if ($i < 0) {
    return undef;
  }
  if (_is_infinite($i)) {
    return $i;
  }

  my $radix = $self->{'radix'};
  my $len = my $n = ($i*0) + 1;  # inherit bignum 1
  $i -= 1;
  for (;;) {
    my $limit = $len*$n*($radix-1);
    ### len: "$len"
    ### n: "$n"
    ### i rem: "$i"
    ### limit: "$limit"

    last if $i < $limit;
    $i -= $limit;
    $n *= $radix;
    $len++;
  }

  ### remainder: $i
  ### $len
  ### $n

  $n += int($i/$len);
  my $pos = $i % $len;

  ### $pos
  ### $n

  if ($self->{'order'} eq 'sorted') {
    my @digits;
    while ($len--) {
      push @digits, $n % $radix;
      $n = int($n/$radix);
    }
    @digits = sort {$a<=>$b} @digits;
    return $digits[$pos];
  }

  if ($self->{'order'} eq 'forward') {
    $pos = $len-1 - $pos;
  }
  while ($pos--) {
    $n = int($n/$radix);
  }
  return $n % $radix;
}

1;
__END__

=for stopwords Ryde Math-NumSeq radix-1

=head1 NAME

Math::NumSeq::AllDigits -- digits of the integers

=head1 SYNOPSIS

 use Math::NumSeq::AllDigits;
 my $seq = Math::NumSeq::AllDigits->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This sequence is the digits of the integers 0, 1, 2, etc,

    0,1,2,3,4,5,6,7,8,9, 1,0, 1,1, 1,2, 1,3, 1,4, 1,5, 1,6,...
    starting i=0

The default is decimal, or the C<radix> parameter can select another base.

The optional C<order> parameter (a string) can control the order of the
digits of each integer,

    "forward"      high to low, 3512 -> 3,5,1,2
    "reverse"      low to high, 3512 -> 2,1,5,3
    "sorted"       sorted, 3512 -> 1,2,3,5

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Digit-E<gt>new ()>

=item C<$seq = Math::NumSeq::Digit-E<gt>new (radix =E<gt> $radix, order =E<gt> $str)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th value from the sequence.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, which simply means digits 0
to radix-1.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::All>

L<Math::NumSeq::SqrtDigits>,
L<Math::NumSeq::DigitLength>,
L<Math::NumSeq::Runs>,
L<Math::NumSeq::ConcatNumbers>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
