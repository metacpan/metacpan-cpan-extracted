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


# cf
# A092360 Spiro-tribonacci numbers: a(n) = sum of three previous terms that are nearest when terms arranged in a spiral.
# A092369 Spiro-tetranacci numbers: a(n) = sum of four previous terms that are nearest when terms arranged in a spiral.
# A094769 Square spiral of sums of selected preceding terms, starting at 0 followed by 1 (a spiral Fibonacci-like sequence).


# math-image --values=SpiroFibonacci --output=numbers --size=78
#
# math-image --values=SpiroFibonacci,recurrence_type=absdiff --output=text --size=60x15


package Math::NumSeq::SpiroFibonacci;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_to_bigint = \&Math::NumSeq::_to_bigint;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Spiro-Fibonacci recurrence.');
use constant default_i_start => 0;

use constant parameter_info_array =>
  [
   # { name    => 'spiral_type',
   #   type    => 'enum',
   #   default => 'square',
   #   choices => ['square','hex'],
   # },
   { name    => 'recurrence_type',
     type    => 'enum',
     choices => ['additive','absdiff'],
     default => 'additive',
   },
   { name    => 'initial_0',
     display => Math::NumSeq::__('Initial value 0'),
     type    => 'integer',
     default => 0,
     width   => 3,
     description => Math::NumSeq::__('Initial value ...'),
   },
   { name    => 'initial_1',
     display => Math::NumSeq::__('Initial value 1'),
     type    => 'integer',
     default => 1,
     width   => 3,
     description => Math::NumSeq::__('Initial value ...'),
   },
  ];

sub characteristic_integer {
  my ($self) = @_;
  return (_is_integer($self->{'initial_0'})
          && _is_integer($self->{'initial_1'}));
}
sub characteristic_smaller {
  my ($self) = @_;
  return ($self->{'recurrence_type'} eq 'absdiff');
}
sub _is_integer {
  my ($n) = @_;
  return ($n == int($n));
}

# FIXME: absdiff range related to least common multiple, maybe
sub values_min {
  my ($self) = @_;
  if ($self->{'initial_0'} >= 0 && $self->{'initial_1'} >= 0) {
    return _min (0, $self->{'initial_0'}, $self->{'initial_1'});
  }
  return undef;
}
sub values_max {
  my ($self) = @_;
  if ($self->{'recurrence_type'} eq 'absdiff') {
    return _max (abs($self->{'initial_0'}),
                 abs($self->{'initial_1'}));
  } else {
    if ($self->{'initial_0'} <= 0 && $self->{'initial_1'} <= 0) {
      return _max ($self->{'initial_0'},
                   $self->{'initial_1'});
    } else {
      return undef;
    }
  }
}
sub _min {
  my $ret = shift;
  while (@_) {
    my $next = shift;
    if ($ret > $next) {
      $ret = $next;
    }
  }
  return $ret;
}
sub _max {
  my $ret = shift;
  while (@_) {
    my $next = shift;
    if ($next > $ret) {
      $ret = $next;
    }
  }
  return $ret;
}


#------------------------------------------------------------------------------

# cf A079422 cumulative absdiff up to n^2
#    A094925 hexagonal 1,1  three around a(n-1)
#    A094926 hexagonal 0,1  three around a(n-1)

my %oeis_anum = ('additive,0,1' => 'A078510',
                 # OEIS-Catalogue: A078510

                 'absdiff,0,1' => 'A079421',
                 # OEIS-Catalogue: A079421 recurrence_type=absdiff

                 # all zeros if initial_0 == initial_1 == 0
                 'additive,0,0' => 'A000004',
                 'absdiff,0,0'  => 'A000004',
                 # OEIS-Other: A000004 initial_1=0
                 # OEIS-Other: A000004 initial_1=0 recurrence_type=absdiff
                );

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{join(',',
                         @{$self}{  # hash slice
                           'recurrence_type',
                             'initial_0',
                               'initial_1'})};
}


#------------------------------------------------------------------------------

use constant 1.02;
use constant _UV_LIMIT => (~0 >> 1);
use constant _IV_NEG_LIMIT => - (_UV_LIMIT >> 1);

# my %spiral_type = (square => { num_sides   => 2,
#                                side_longer => -1,
#                              },
#                    hex => { num_sides   => 6,
#                             side_longer => 1,
#                           },
#                   );

sub rewind {
  my ($self) = @_;
  $self->{'i'}     = $self->i_start;
  $self->{'queue'} = [$self->{'initial_0'}, $self->{'initial_1'}];
  $self->{'num_sides'}  = 2;
  $self->{'side_len'}   = 1;
  $self->{'side'}  = $self->{'num_sides'};
  $self->{'count'} = 2;
}

sub next {
  my ($self) = @_;
  ### next(): "i=$self->{'i'}  side_len=$self->{'side_len'} side=$self->{'side'} count=$self->{'count'}"

  my $queue = $self->{'queue'};
  my $i = $self->{'i'}++;
  if ($i < 2) {
    ### initial queue ...
    return ($i, $queue->[$i]);
  }

  my $value;
  if ($self->{'recurrence_type'} eq 'absdiff') {
    $value = abs($queue->[-1] - $queue->[0]);
  } else {
    $value = $queue->[-1] + $queue->[0];
  }
  if (! ref $value && ($value >= _UV_LIMIT || $value <= _IV_NEG_LIMIT)) {
    $queue->[-1] = _to_bigint($queue->[-1]);
  }

  push @$queue, $value;
  my $count = --$self->{'count'};
  ### count down to: $count

  if ($count > 0 && $self->{'side_len'} >= 2) {
    shift @$queue;
  } elsif ($count < 0) {
    ### end of side, next side ...
    if (--$self->{'side'} <= 0) {
      ### end of sides, next loop ...
      $self->{'side'} = $self->{'num_sides'};
      $self->{'side_len'}++;
    }
    $self->{'count'} = $self->{'side_len'};
  } else {
    ### count==0 corner ...
  }
  return ($i, $value);
}

# sub new {
#   ### SpiroFibonacci new(): @_
#   my $self = shift->SUPER::new(@_);
#   require Math::PlanePath::SquareSpiral;
#   $self->{'path'} = Math::PlanePath::SquareSpiral->new;
#   $self->{'cache'} = [];
#   $self->{'cache'}->[1] = $self->{'initial_0'};
#   $self->{'cache'}->[2] = $self->{'initial_1'};
#   return $self;
# }
#
# sub ith {
#   my ($self, $i) = @_;
#   ### SpiroFibonacci ith(): $i
#
#   if (_is_infinite($i)) {
#     return undef;
#   }
#
#   if ($i <= 0) {
#     return undef;
#   }
#   my $orig_i = $i;
#
#   my $cache = $self->{'cache'};
#   my $path = $self->{'path'};
#   my @pending = ($i);
#   my $total = 0;
#
#   while (@pending) {
#     ### @pending
#     $i = pop @pending;
#     if (defined $cache->[$i]) {
#       if ($self->{'recurrence_type'} eq 'absdiff') {
#         $total ^= $cache->[$i];
#       } else {
#         $total += $cache->[$i];
#       }
#     } else {
#       my ($x,$y) = $path->n_to_xy($i);
#       my $pi = 0;
#       foreach my $dxdy ([0,1],[0,-1],
#                         [1,0],[-1,0]) {
#         my ($dx,$dy) = @$dxdy;
#         my $n = $path->xy_to_n($x+$dx,$y+$dy);
#         if ($n < $i-1 && $n > $pi) {
#           ### straight at: "i=$i,x=$x,y=$y   dx=$dx dy=$dy pi=$n"
#           $pi = $n;
#         }
#       }
#       if (! $pi) {
#         foreach my $dxdy ([1,1],[1,-1],
#                           [-1,1],[-1,-1]) {
#           my ($dx,$dy) = @$dxdy;
#           my $n = $path->xy_to_n($x+$dx,$y+$dy);
#           if ($n < $i-1 && $n > $pi) {
#             ### diagonal at: "i=$i,x=$x,y=$y   dx=$dx dy=$dy pi=$n"
#             $pi = $n;
#           }
#         }
#       }
#       if (@pending > 100000) { die; }
#       push @pending, $pi;
#       push @pending, $i-1;
#     }
#   }
#   $self->{'cache'}->[$orig_i] = $total;
#
#   ### $total
#   return $total;
# }

1;
__END__

=for stopwords Ryde Math-NumSeq BigInt spiro-Fibonacci

=head1 NAME

Math::NumSeq::SpiroFibonacci -- recurrence around a square spiral

=head1 SYNOPSIS

 use Math::NumSeq::SpiroFibonacci;
 my $seq = Math::NumSeq::SpiroFibonacci->new (cbrt => 2);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the spiro-Fibonacci numbers by Neil Fernandez.  The sequence is a
recurrence

    SF[0] = 0
    SF[1] = 1
    SF[i] = SF[i-1] + SF[i-k]

where the offset k is the closest point on the on the preceding loop of a
square spiral.  The initial values are

    0, 1, 1, ..., 1, 2, 3, 4, ... 61, 69, 78, 88, 98, 108, ...
    starting i=0

On the square spiral this is

     98-88-78-69-61-54-48
      |                 |
    108 10--9--8--7--6 42
      |  |           |  |
        11  1--1--1  5 36
         |  |     |  |  |
        12  1  0--1  4 31
         |  |        |  |
        13  1--1--2--3 27
         |              |
        14-15-16-18-21-24

Value 36 on the right is 31+5, being the immediately preceding 31 and the
value on the next inward loop closest to that new 36 position.

At the corners the same inner value is used three times, so for example
42=36+6, then 48=42+6 and 54=48+6, all using the corner "6".  For the
innermost loop SF[2] through SF[7] the "0" at the origin is the inner value,
hence the run of seven 1s at the start.

=head2 Absolute Differences

Optional C<recurrence_type =E<gt> 'absdiff'> changes the recurrence formula
to an absolute difference

    SF[i] = abs (SF[i-1] - SF[i-k])

With the default initial values SF[0]=0 and SF[1]=1 this behaves as an XOR,
always giving 0 or 1.

    0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, ...

The result plotted around the square spiral is similar to some of the
cellular automaton patterns which work on xor feedback.

    *** *    *  **       *     **  **      * * * *  * * **
    * *  *****   *        *** * * * *      ******** *****
     **   * * ****         * ********      *       **    *
      *    **  * *          **      *      **      * *   *
    ***     *   **           *     **      * *     ****  *
     * ******    *            *** * *      ****    *   * *
      ** * * *****             * ***       *   *   **  ***
    *** **  ** * *              **o**      **  **  * * *
    * *  *   *  **               * * *     * * * * ******
     **   ****   *              *  * **    *********     *
    ** **** * ****              ***    *   *        *    *
    * ** * **  * *              * *******  **       **   *
     ** **  *   **              ** * * * * * *      * *  *
    ** ** ***    *              *  **  * ******     **** *
     *  *  * *****              *** ***        *    *   **

=head2 Initial Values

Optional C<initial_0> and C<initial_1> can give different initial i=0 and i=1
values.  For example C<initial_0=E<gt>1, initial_1=E<gt>0> gives

    1, 0, 1, 2, 3, 4, 5, 6, 6, 6, 6, 7, 8, 9, 11, 14, 17, 20, ...

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::SpiroFibonacci-E<gt>new ()>

Create and return a new sequence object.

=item C<($i, $value) = $seq-E<gt>next()>

Return the next index and value in the sequence.

When C<$value> exceeds the range of a Perl unsigned integer the return is
promoted to a C<Math::BigInt> to keep full precision.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Fibonacci>

L<Math::PlanePath::SquareSpiral>

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
