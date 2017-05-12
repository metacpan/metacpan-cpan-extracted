# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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

package Math::NumSeq::HofstadterFigure;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;

use Math::NumSeq;
@ISA = ('Math::NumSeq');

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Hofstadter Figure');
use constant description => Math::NumSeq::__('Hofstadter figure sequence.');
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant i_start => 1;

use constant parameter_info_array =>
  [
   { name    => 'start',
     type    => 'integer',
     default => '1',
     width   => 2,
     minimum => 1,
     # description => Math::NumSeq::__(''),
   },
  ];

sub values_min {
  my ($self) = @_;
  return $self->{'start'};
}

#------------------------------------------------------------------------------

# A005228 - seq and first diffs make all integers, increasing
#  A030124 - the first diffs
#
# cf A061577 - starting from 2
#     A061578 - starting from 2 first diffs
#     2, 3, 7, 12, 18, 26, 35, 45,
#      1, 4, 5,  6,   8,  9, 10, 11, 13,
#
#    A140778 - seq and first diffs make all positive integers,
#     each int applied to one of the two in turn
#      A140779 - its first diffs
#
#    A037257 - seq + first diffs + second diffs make all integers
#     A037258 - the first diffs
#     A037259 - the second diffs
#    A081145
#
my @oeis_anum = (
                 # OEIS-Catalogue array begin
                 undef,     # start=0
                 'A005228', #
                 'A061577', # start=2
                 'A022935', # start=3
                 'A022936', # start=4
                 'A022937', # start=5
                 'A022938', # start=6
               # OEIS-Catalogue array end
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'start'}];
}

#------------------------------------------------------------------------------

# start S
# S, S+1, S+2, ..., S+(S-1), S+(S+1), S+(S+2)

# $upto[0] is the previous value returned
# $inc[0] is the amount to increment it by next time
#
# $upto[1] is the sequence at a previous position
# if $inc[0] == $upto[1] then that increment must be skipped,
# and advance $upto[1] for the next to skip#
#
# initial
# upto[0] = 1
# inc[0] = 0
#
# return 1+0=1, small inc[0] -> 2
# upto[0] = 1
# inc[0] = 2
#
# return 1+2=3, small inc[0] -> 4
# upto[0] = 3
# inc[0] = 4
#
# return 3+4=7, small inc[0] 4 -> 5
# upto[0] = 7
# inc[0] = 5
#
# return 7+5=12, small inc[0] 5 -> 6
# upto[0] = 12
# inc[0] = 6
#
# return 12+6=18, small inc[0] 6 -> outside
# upto[0] = 12
# inc[0] = 8
# upto[1] = 12
# inc[1] = 6
#
# inc[0]==upto[1] so skip to inc[0]=4
# add 4 to return upto[0]=3+4=7
# $inc[0]++
# next upto[1] is 7
# upto[0] = 7
# upto[1] = 7
# inc[0] = 5
# inc[1] = 4
#
# add 7+5 to 12, inc[0]++
# upto[0] = 12
# upto[1] = 7
# inc[0] = 6
# inc[1] = 4
#
# add 12+6=18, inc[0]++
# upto[0] = 18
# upto[1] = 7
# inc[0] = 7
# inc[1] = 4
#
# inc[0]==upto[1] so skip to inc[0]=8
# add 8 to return upto[0]=18+8=26
# step upto[1] add inc[1]++ to 7+5=12
# upto[0] = 26
# upto[1] = 12
# inc[0] = 7
# inc[1] = 6
#

# start=1
# seq  1, 3, 7, 12, 18, 26, 35, 45, 56, 69, 83, 98, 114, 131, 150, 170, 191,
# diffs  2, 4, 5, 6,  8,  9,  10, 11, 13, 14, 15, 16,  17,  19,  20,  21, 22,
#
# start=2
# seq  2, 3, 7, 12, 18, 26,
# diffs  1  4  5   6   8
#
# start=4
# seq  4, 5, 7, 10, 16, 24,
# diffs  1  2  3  6   8   9
#
# start=5
# seq  5, 6, 8, 11, 15, 22, 31,
# diffs  1  2  3  4,  7   9   10
#
# start=6
# seq  6, 7, 9, 12, 16, 21, 29,
# diffs  1  2  3  4,  5,  8   10
#
# start=7
# seq  7, 8, 10, 13, 17, 22, 28, 37
# diffs  1  2   3  4,  5,  6   9   11

my @small_inc
  = (undef, # start=0 impossible

     # 0      1      2      3      4  5      6  7
     #
     [ 2, undef,     4, undef,     5, 6,     7  ],  # start=1
     [ 1,     4, undef, undef,     5, 6,     7  ],  # start=2

     # start=3
     # seq  3, 4, 6, 11, 18, 26,
     # diffs  1  2  5   7   8   9
     #
     # 0  1  2      3      4  5      6  7
     [ 1, 2, 5, undef, undef, 7, undef, 8 ],

     # # start=4
     # [ 1,     2,     3,     6,    ],

     # # start=5
     # [ 1, 2, 3, 4, 7, undef, undef, 9 ],

     # # start=6
     # # 0  1  2  3  4  5
     # [ 1, 2, 3, 4, 5, 8  ],

     # # start=7
     # # 0  1  2  3  4  5  6
     # [ 1, 2, 3, 4, 5, 6, 9  ],
    );
my @small_upto = (undef, # 0
                  7,     # 1
                  7,     # 2
                  11,    # 3

                  # 7,     # 4
                  # 11,    # 5
                  # 9,     # 6
                  # 10,    # 7
                 );
my @small_upto_inc = (undef,  # 0
                      5,      # 1
                      5,      # 2
                      7,      # 3

                      # 3,      # 4
                      # 4,      # 5
                      # 3,      # 6
                      # 3,      # 7
                     );
sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;

  my $start = $self->{'start'};
  $self->{'small_inc'}  = $small_inc[$start];

  if ($self->{'small_inc'}) {
    $self->{'grow_upto'} = $small_upto[$start];
    $self->{'grow_inc'} = $small_upto_inc[$start];
  } else {
    $self->{'small_inc'} = [ (1 .. $start-1), $start+2 ];
    $self->{'grow_upto'} = $start+3;
    $self->{'grow_inc'} = 3;
  }
  $self->{'upto'} = [ $start,
                      $self->{'grow_upto'} ];
  $self->{'inc'}  = [ 0,
                      $self->{'grow_inc'} ];
}

# # 1->2->4->5->6->7
# #                    0  1  2    3    4  5  6
# my @small_inc = (undef, 2, 4, undef, 5, 6);

sub next {
  my ($self) = @_;
  ### HofstadterFigure next(): "$self->{'i'}"
  ### upto: join (', ',@{$self->{'upto'}})
  ### inc : join (', ',@{$self->{'inc'}})

  my $i = $self->{'i'}++;
  my $upto = $self->{'upto'};
  my $inc = $self->{'inc'};

  my $add = $inc->[0]++;
  ### prospective add: $add

  if (defined (my $next_inc = $self->{'small_inc'}->[$add])) {
    ### small next_inc: $next_inc
    $inc->[0] = $next_inc;

  } elsif ($add >= $upto->[1]) {
    ### must skip this increment ...
    ### add now: $inc->[0]
    $add = $inc->[0]++;

    # diff=26 already seen (6), at i=22 value=311 prev_value=285

    my $pos = 1;
    for (;;) {
      ### $pos
      if ($pos >= $#$upto) {
        ### grow ...
        push @$upto, $self->{'grow_upto'};
        push @$inc, $self->{'grow_inc'};
      }

      my $posadd = $inc->[$pos]++;
      ### $posadd
      $upto->[$pos] += $posadd;

      if (defined (my $next_inc = $self->{'small_inc'}->[$posadd])) {
        ### small pos next_inc: $next_inc
        $inc->[$pos] = $next_inc;
        last;
      }
      if ($posadd < $upto->[$pos+1]) {
        ### less than next upto: $upto->[$pos+1]
        last;
      }
      $upto->[$pos]++; # skip and to next level
      $inc->[$pos]++;
      $pos++;
    }
  }
  ### $add
  ### for return value: $upto->[0] + $add
  return ($i,
          ($upto->[0] += $add));
}

1;
__END__

=for stopwords Ryde Math-NumSeq incrementing

=head1 NAME

Math::NumSeq::HofstadterFigure -- sequence excludes its own first differences

=head1 SYNOPSIS

 use Math::NumSeq::HofstadterFigure;
 my $seq = Math::NumSeq::HofstadterFigure->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is Douglas Hofstadter's "figure" sequence which comprises all integers
except those which are differences between its own successive values,

    1, 3, 7, 12, 18, 26, 35, 45, 56, 69, 83, 98, ...

So for example at value=1 the next cannot be 2 because the difference 2-1=1
is already in the sequence, so value=3 with difference 3-1=2 is next.  Then
the next cannot be 4 since 4-3=1 is already in the sequences, and likewise
5-3=2 and 6-3=3, so the next is value=7 with 7-3=4 not already in the
sequence.

The effect is that the sequence increments by 1,2,3,4, etc but excluding
values of the sequence itself.  This makes it close to the Triangular
numbers i*(i+1)/2, but incrementing by a little extra at the places it skips
its own values.

=head2 Start Value

The optional C<start =E<gt> $value> can give the first value for the
sequence, instead of the default 1.  For example starting at 2

    2, 3, 7, 12, 18, 26, 35, 45, 56, ...

or starting at 5

    5, 6, 8, 11, 15, 22, 31, 41, 53, 66, ...

The differences are still the values not in the sequence, so for example
starting at 5 means the differences are 1, 2, 3, 4 before skipping 5 and 6.

In general the effect is to push the first skip up a bit, but still settles
down to grow roughly like the triangular numbers.

The start > must be 1 or more.  If the start was 0 then the first value and
first difference would always be the same, contradicting the conditions for
the sequence.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::HofstadterFigure-E<gt>new ()>

=item C<$seq = Math::NumSeq::HofstadterFigure-E<gt>new (start =E<gt> $value)>

Create and return a new sequence object.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Kolakoski>

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
