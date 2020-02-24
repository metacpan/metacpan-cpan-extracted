# Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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


package Math::NumSeq::PowerSieve;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 74;

use Math::NumSeq 7; # v.7 for _is_infinite()
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Lucky Numbers');
use constant description => Math::NumSeq::__('Sieved out multiples according to the sequence itself.');
use constant values_min => 1;
use constant i_start => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

use constant parameter_info_array =>
  [
   { name          => 'base',
     share_key     => 'base_2',
     type          => 'integer',
     display       => Math::NumSeq::__('From Radix'),
     default       => 2,
     minimum       => 2,
     width         => 3,
     # description => Math::NumSeq::__('...'),
   },
  ];

#------------------------------------------------------------------------------
#    A007951 - ternary sieve, dropping 3rd, 6th, 9th, etc
#    1,2,_,4,5,_,7,8,_,10,11,_,12,13,_,14,15,_
#                              ^9th
#    1,2,4,5,7,8,10,11,14,16,17,19,20,22,23,25,28,29,31,32,34,35,37,38,41,     

my @oeis_anum;
$oeis_anum[3] = 'A007951';
# OEIS-Other: A007951 multiple=3

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'base'}];
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'value'} = 0;
  my $base = $self->{'base'};
  $self->{'count'} = [ $base ];
  $self->{'remaining'}  = [ $base ];
}

# ENHANCE-ME: Defer pushing each value only the count array until needed.
# Might keep array size down to i/log(i) instead of i.
#
sub next {
  my ($self) = @_;
  ### PowerSieve next(): "i=$self->{'i'}"
  ### count: $self->{'count'}
  ### remaining: $self->{'remaining'}
  ### value: $self->{'value'}

  my $count = $self->{'count'};
  my $remaining = $self->{'remaining'};
  my $value = $self->{'value'};

 OUTER: for (;;) {
    $value++;
    ### $value
    foreach my $p (0 .. $#$remaining) {
      if (--$remaining->[$p] <= 0) {
        ### exclude at: "p=$p  count=$self->{'count'}->[$p]"
        $remaining->[$p] = $self->{'count'}->[$p];
        next OUTER;
      }
    }
    $self->{'value'} = $value;

    my $i = $self->{'i'}++;
    if ($i > $count->[-1]) {
      my $c = $count->[-1] * $self->{'base'};
      push @$count, $c;
      push @$remaining, $c - $i;
      ### extend: "count=$count->[-1]  remaining=$remaining->[-1]"
    }
    return ($i, $value);
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::PowerSieve -- sieved out powers

=head1 SYNOPSIS

 use Math::NumSeq::PowerSieve;
 my $seq = Math::NumSeq::PowerSieve->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is repeated sieving out of powers of a base integer.  The default is 2

    1, 3, 5, 9, 11, 13, 17, 21, 25, 27, 29, 33, 35, 37, 43, 49, ...

The sieve starts with all integers

    1,2,3,4,5,6,7,8,9,10,11,12,13

Then sieve out all the multiple of 2 positions (which leaves the odd
numbers)

    1,3,5,7,9,11,13,15,17,19,21,23,25,...

Then sieve out all the multiple of 4 positions, for example 7 at position 4
is the first removed

    1,3,5,9,11,13,17,19,21,25,...

Then multiple of 8 positions (value 19 here), then 16, 32, etc.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::PowerSieve-E<gt>new ()>

Create and return a new sequence object.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::ReRound>,
L<Math::NumSeq::ReReplace>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
