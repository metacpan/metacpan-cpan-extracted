# Copyright 2012, 2013, 2014 Kevin Ryde

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


# http://oeis.org/wiki/Lucky_numbers
#
# Gardiner, R. Lazarus, N. Metropolis and S. Ulam,"On certain sequences of
# integers defined by sieves", Mathematics Magazine 29:3 (1955),
# pp. 117-122.


package Math::NumSeq::LuckyNumbers;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 72;

use Math::NumSeq 7; # v.7 for _is_infinite()
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('Lucky Numbers');
use constant description => Math::NumSeq::__('Sieved out multiples according to the sequence itself.');
use constant values_min => 1;
use constant i_start => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

#------------------------------------------------------------------------------
# cf A145649 - 0,1 characteristic of Lucky numbers
#    A050505 - complement, the non-Lucky numbers
#
#    A007951 - ternary sieve, dropping 3rd, 6th, 9th, etc
#    1,2,_,4,5,_,7,8,_,10,11,_,12,13,_,14,15,_
#                              ^9th
#    1,2,4,5,7,8,10,11,14,16,17,19,20,22,23,25,28,29,31,32,34,35,37,38,41,
#
use constant oeis_anum => 'A000959';

#------------------------------------------------------------------------------

# i=22
# mod: '8,12,14,20,24'
# int(21/24)=0 to i=21
# int(21/20)=1 to i=22
# int(22/14)=1 to i=23     two_pos=2 three_pos=1
# int(23/12)=1 to i=24
# int(24/8)=3 to i=27
# int(27/6)=4 to i=31
# int(31/2)=15 to i=46
# 2*46+1=93
#
# i+1 then twos advance for +1 more = +2
# threes advance
# i>3*mod[pos]  i-=2 pos++
# i-2>3*mod[pos+1]
#     3*2

sub rewind {
  my ($self) = @_;
  $self->{'i'}         = $self->i_start;
  $self->{'mod'}       = [ 8 ];
  $self->{'mod_pos'}   = 0;
  $self->{'one_pos'}   = 0;
  $self->{'two_pos'}   = 0;
  $self->{'three_pos'} = 0;
}

my @twelve = (1,3,
              7,9,
              13,15,
              21,
              25,27,
              31,33,
              37
             );

sub next {
  my ($self) = @_;
  ### LuckyNumbers next(): "i=$self->{'i'}"

  my $ret_i = $self->{'i'}++;
  my $i = $ret_i - 1;
  my $mod = $self->{'mod'};
  if ($i >= $mod->[-1]) {
    ### extend mod ...
    my $mod_i = $#$mod + 4;
    my $mod_pos = $self->{'mod_pos'};
    if ($mod_i >= $mod->[$mod_pos]) {
      $self->{'mod_pos'} = ++$mod_pos;
    }
    push @$mod, _ith_by_mod($mod, $mod_i, $mod_pos) - 1;
  }

  # my $one_pos = $#$mod;
  my $two_pos = $self->{'two_pos'};

  ### mod: join(',',@{$self->{'mod'}})
  ### at: "i=$i one_pos=$#$mod two_pos=$self->{'two_pos'} diff=".($#$mod - $two_pos)

  $i += $#$mod - $two_pos;
  ### after ones: "i=$i cmp ".(2*$mod->[$two_pos])

  if ($i > 2*$mod->[$two_pos]) {
    ### advance two ...
    $self->{'two_pos'} = ++$two_pos;
    $i--;
  }
  ### after twos: "i=$i  two_pos=$two_pos  three_pos=$self->{'three_pos'}"

  my $three_pos = $self->{'three_pos'};
  $i += 2*($two_pos - $three_pos);
  ### increased i with twos: $i

  ### cmp: "i=$i three_pos=$three_pos  cmp ".(3*$mod->[$three_pos])
  if ($i > 3*$mod->[$three_pos]) {
    ### advance three ...
    $self->{'three_pos'} = ++$three_pos;
    $i -= 2;
  }

  return ($ret_i,
          _ith_by_mod($mod, $i, $three_pos));
}

sub _ith_by_mod {
  my ($mod, $i, $pos) = @_;
  ### _ith_by_mod(): "i=$i pos=$pos is mods=".join(',',@{$mod}[0..$pos-1])

  while (--$pos >= 0) {
    ### at: "pos=$pos i=$i"
    $i += int($i / $mod->[$pos]);
  }
  ### final: "i=$i  result=".(int($i/12)*21 + $twelve[$i%12])
  return int($i/12)*42 + $twelve[$i%12];
}

# i~=value/log(value)
#
use Math::NumSeq::Primes;
*value_to_i_estimate = \&Math::NumSeq::Primes::value_to_i_estimate;

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::LuckyNumbers -- sieved out multiples by the sequence itself

=head1 SYNOPSIS

 use Math::NumSeq::LuckyNumbers;
 my $seq = Math::NumSeq::LuckyNumbers->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the so-called "Lucky" numbers obtained by sieving out multiples
taken from the sequence itself

    starting i=1
    1, 3, 7, 9, 13, 15, 21, 25, 31, 33, 37, 43, 49, 51, 63, 67, ...

The sieve begins with the odd numbers

    1,3,5,7,9,11,13,15,17,19,21,23,25,...

Then sieve[2]=3 from the sequence means remove every third number, counting
from the start, so remove 5,11,17, etc to leave

    1,3,7,9,13,15,19,21,25,...

Then the next value sieve[3]=7 means remove every seventh number, so 19 etc,
to leave

    1,3,7,9,13,15,21,25,...

Then sieve[4]=9 means remove every ninth from what remains, and so on.  In
each case the removals count from the start of the values which remain at
that stage.

It can be shown the values grow at roughly the same rate as the primes, i =~
value/log(value).

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::LuckyNumbers-E<gt>new ()>

Create and return a new sequence object.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.  It can be shown
that values grow roughly at the same rate as the primes,

    i ~= value/log(value)

So C<value_to_i_estimate()> returns C<$value/log($value)>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::ReRound>,
L<Math::NumSeq::ReReplace>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014 Kevin Ryde

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
