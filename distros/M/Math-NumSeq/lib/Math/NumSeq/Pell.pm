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

package Math::NumSeq::Pell;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq::Base::Sparse;
@ISA = ('Math::NumSeq::Base::Sparse');

use Math::NumSeq 7; # v.7 for _is_infinite()
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

# uncomment this to run the ### lines
# use Smart::Comments;


# a(r+s) = a(r)*a(s+1) + a(r-1)*a(s)
#
# P[2k+1] = P[k]^2 + P[k+1]^2

# C[k]^2 - 8*P[k]^2 = 4(-1)^n

# use constant name => Math::NumSeq::__('Pell Numbers');
use constant description => Math::NumSeq::__('The Pell numbers 0, 1, 2, 5, 12, 29, 70, etc, being P[k]=2*P[k-1]+P[k-2] starting from 0,1.');
use constant i_start => 0;
use constant values_min => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

# cf A001333 cont frac numerators, being P[n]+P[n-1]
#    A002203 Pell companion
#    A077985 P[-n] negatives
#    A099011 Pell pseudoprimes
#      Pell(N) == kronecker(2,N) mod N for all primes and some pseudos
#    A048739 cumulative Pell, starting at value=1
#
use constant oeis_anum => 'A000129'; # pell


#------------------------------------------------------------------------------
# the biggest f0 for which both f0 and f1 fit into a UV, and which therefore
# for the next step will require BigInt
#
my $uv_limit;
my $uv_i_limit = -1; # index of $prev_f0
{
  # Float integers too in 32 bits ?
  # my $max = 1;
  # for (1 .. 256) {
  #   my $try = $max*2 + 1;
  #   ### $try
  #   if ($try == 2*$max || $try == 2*$max+2) {
  #     last;
  #   }
  #   $max = $try;
  # }
  my $max = ~0;

  # 2*f1+f0 > max
  # f0 > max-2*f1
  # check max-2*f1 as the stopping point, so that if i=UV_MAX then won't
  # overflow a UV trying to get to f1>=i
  #
  my $f0 = 0;
  my $f1 = 1;
  my $prev_f0;
  while ($f1 <= ($max>>1) && $f0 <= $max - 2*$f1) {
    $prev_f0 = $f0;
    ($f1,$f0) = (2*$f1+$f0,$f1);
    $uv_i_limit++;
  }

  ### Pell UV limit ...
  ### $prev_f0
  ### $f0
  ### $f1
  ### ~0 : ~0

  $uv_limit = $prev_f0;

  ### $uv_limit
  ### $uv_i_limit
  ### ith: __PACKAGE__->ith($uv_i_limit)

  __PACKAGE__->ith($uv_i_limit) == $uv_limit
    or warn "Oops, wrong uv_i_limit";
}

sub seek_to_i {
  my ($self, $i) = @_;
  ### Pell rewind() ...
  ($self->{'f0'}, $self->{'f1'}) = $self->ith_pair($i);
  $self->{'i'} = $i;
}
sub rewind {
  my ($self) = @_;
  ### Pell rewind() ...
  $self->{'i'} = $self->i_start;
  $self->{'f0'} = 0;
  $self->{'f1'} = 1;
}
sub next {
  my ($self) = @_;
  (my $ret,
   $self->{'f0'},
   $self->{'f1'})
   = ($self->{'f0'},
      $self->{'f1'},
      $self->{'f0'} + 2*$self->{'f1'});

  if ($ret == $uv_limit) {
    ### go to bigint f1 ...
    $self->{'f1'} = _to_bigint($self->{'f1'});
  }

  return ($self->{'i'}++, $ret);
}

# P[k-2] = P[k] - 2*P[k-1]
sub _UNTESTED_prev {
  my ($self) = @_;
  ($self->{'f0'},
   $self->{'f1'},
   my $ret)
    = ($self->{'f0'} + 2*$self->{'f1'},
       $self->{'f0'},
       $self->{'f1'});

  if (abs($ret) == $uv_limit) {
    ### go to bigint f1 ...
    $self->{'f1'} = _to_bigint($self->{'f1'});
  }

  return (--$self->{'i'}, $ret);
}

# P[1] = 1
# P[0] = 0
# P[-1] = 1      so  1+2*0 == 1
# P[-2] = -2     so -2+2*1 == 0
# P[-3] = 5      so  5+2*-2 == 1
# so P[-i] = P[i] when i even, or -P[i] when i odd
#
sub ith {
  my ($self, $i) = @_;
  ### ith(): $i
  if (_is_infinite($i)) {
    return $i;
  }

  my $neg;
  if ($i < 0) {
    $i = -$i;
    $neg = ($i % 2 == 0);
  }
  ### $neg

  my $f0 = ($i * 0);  # inherit bignum 0
  my $f1 = $f0 + 1;   # inherit bignum 1

  if ($i > $uv_i_limit && ! ref $f0) {
    ### automatic BigInt as not another bignum class ...
    $f0 = _to_bigint($f0);
    $f1 = _to_bigint($f1);
  }

  # ENHANCE-ME: use one of the powering algorithms
  while ($i-- > 0) {
    ### at: "i=$i   $f0, $f1"
    ($f0,$f1) = ($f1, $f0 + 2*$f1);
  }
  ### final: "f0=$f0,  f1=$f1"
  return ($neg ? -$f0 : $f0);
}

# P[i] = ( (1+sqrt(2))^i - (1-sqrt(2))^i ) / (2*sqrt(2))
# log(P[i]) ~= i*log(1+sqrt(2)) - log(2*sqrt(2))
# i = (log(P[i]) + log(2*sqrt(2))) / log(1+sqrt(2))

use Math::NumSeq::Fibonacci;
*_blog2_estimate = \&Math::NumSeq::Fibonacci::_blog2_estimate;

sub value_to_i_estimate {
  my ($self, $value) = @_;
  ### Pell value_to_i_estimate(): "$value"

  if (_is_infinite($value)) {
    return $value;
  }
  if ($value <= 0) {
    return 0;
  }

  if (defined (my $blog2 = _blog2_estimate($value))) {
    ### $blog2
    return int( ($blog2 + (log(2*sqrt(2))/log(2)))
                / (log(1+sqrt(2))/log(2)) );
  }
  return int( (log($value) + log(2*sqrt(2)))
              / log(1+sqrt(2)) );
}

1;
__END__

=for stopwords Ryde Math-NumSeq Pell

=head1 NAME

Math::NumSeq::Pell -- Pell numbers

=head1 SYNOPSIS

 use Math::NumSeq::Pell;
 my $seq = Math::NumSeq::Pell->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The Pell numbers

    0, 1, 2, 5, 12, 29, 70, 169, 408, 985, 2378, 5741, 13860, ...
    starting i=0

where

    P[k] = 2*P[k-1] + P[k-2] starting P[0]=0 and P[1]=1

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Pell-E<gt>new ()>

Create and return a new sequence object.

=item C<($i, $value) = $seq-E<gt>next()>

Return the next index and value in the sequence.

When C<$value> exceeds the range of a Perl unsigned integer the return is a
C<Math::BigInt> to preserve precision.

=item C<$seq-E<gt>seek_to_i($i)>

Move the current sequence position to C<$i>.  The next call to C<next()>
will return C<$i> and corresponding value.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th Pell number.

For negative <$i> the sequence is extended backwards as
P[i]=P[i+2]-2*P[i+1].  The effect is the same numbers but negative at
negative even i.

     i     P[i]
    ---    ----
     0       0
    -1       1
    -2      -2       <----+ negative at even i
    -3       5            |
    -4     -12       <----+

When C<$value> exceeds the range of a Perl unsigned integer the return is a
C<Math::BigInt> to preserve precision.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, so is a positive Pell
number.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.  See L</Value to i
Estimate> below.

=back

=head1 FORMULAS

=head2 Value to i Estimate

The Pell numbers are a Lucas sequence and hence a power

           (1+sqrt(2))^i - (1-sqrt(2))^i
    P[i] = -----------------------------     # exactly
                   2*sqrt(2)

Since abs(1-sqrt(2)) E<lt> 1 that term approaches zero, so taking logs the
rest gives i approximately

         log(value) + log(2*sqrt(2))
    i ~= ---------------------------
              log(1+sqrt(2))

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Fibonacci>,
L<Math::NumSeq::LucasNumbers>

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
