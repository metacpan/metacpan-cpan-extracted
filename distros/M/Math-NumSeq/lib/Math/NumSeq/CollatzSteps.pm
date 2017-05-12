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


# step_type   up,down, up_reduced, down_reduced
# diff=down-up  frac=up/down
# completeness
# to_peak, after_peak, to_drop, to_last_drop,
# to_pow2 after_pow2
# first_drop  first_down
# last_drop   last_down
# peak
# 

# Maybe "before_drop", "after_drop"
# Maybe "before_peak", "after_peak"
# Maybe +1 count steps from 1.
#

# on_values=>'even' is 2*i gives +1 for "both" and "down", no change to "up"
# on_values=>'odd' is 2*i+1
#   starts 3*(2i+1)+1 = 6i+4 -> 3i+2
#
# i=0 for odd same as Odd->ith() ?

# 2^E(N) = 3^O(N) * N * Res(N)
# log(2^E(N)) = log(3^O(N) * N * Res(N))
# log(2^E(N)) = log(3^O(N)) + log(N) + log(Res(N))
# E(N)*log(2) = O(N)*log(3) + log(N) + log(Res(N))
# log(Res(N)) = O(N)*log(3) - E(N)*log(2) + log(N)

# "Glide" how many steps to get a value < N.
#

package Math::NumSeq::CollatzSteps;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
# use Smart::Comments;

# use constant name => Math::NumSeq::__('Collatz Steps');
sub description {
  my ($self) = @_;
  if (ref $self) {
    if ($self->{'step_type'} eq 'up') {
      return Math::NumSeq::__('Number of up steps to reach 1 in the Collatz "3n+1" problem.');
    }
    if ($self->{'step_type'} eq 'down') {
      return Math::NumSeq::__('Number of down steps to reach 1 in the Collatz "3n+1" problem.');
    }
  }
  return Math::NumSeq::__('Number of steps to reach 1 in the Collatz "3n+1" problem.');
}

sub default_i_start {
  my ($self) = @_;
  return ($self->{'on_values'} eq 'odd' ? 0 : 1);
}
sub values_min {
  my ($self) = @_;
  return ($self->ith($self->i_start));
}
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;

use constant parameter_info_array =>
  [
   # { name      => 'end_type',
   #   share_key => 'end_type_1drop',
   #   display   => Math::NumSeq::__('End Type'),
   #   type      => 'enum',
   #   default   => 'one',
   #   choices   => ['one','drop','to_peak','from_peak','pow2'],
   #   choices_display => [Math::NumSeq::__('One'),
   #                       Math::NumSeq::__('Drop'),
   #                       Math::NumSeq::__('To Peak'),
   #                       Math::NumSeq::__('From Peak'),
   #                       Math::NumSeq::__('Pow2'),
   #                      ],
   #   # description => Math::NumSeq::__(''),
   # },

   { name      => 'step_type',
     share_key => 'step_type_bothupdown',
     display   => Math::NumSeq::__('Step Type'),
     type      => 'enum',
     default   => 'both',
     choices   => ['both','up','down',
                   # 'diff', 'both+1',
                  ],
     choices_display => [Math::NumSeq::__('Both'),
                         Math::NumSeq::__('Up'),
                         Math::NumSeq::__('Down'),
                        ],
     description => Math::NumSeq::__('Which steps to count, the 3*n+1 ups, the n/2 downs, or both.'),
   },

   # secret extra 'odd1' for 2*i-1 starting i=1 to help offset of A075680
   { name      => 'on_values',
     share_key => 'on_values_aoe',
     display   => Math::NumSeq::__('On Values'),
     type      => 'enum',
     default   => 'all',
     choices   => ['all','odd','even'],
     choices_display => [Math::NumSeq::__('All'),
                         Math::NumSeq::__('Odd'),
                         Math::NumSeq::__('Even')],
     description => Math::NumSeq::__('The values to act on, either all integers or just odd or even.'),
   },
  ];

#------------------------------------------------------------------------------
# cf
#    A139399 steps to reach cycle 4-2-1, so is steps-2 except at 4,2,1
#    A112695   similar
#    A064433 steps to reach 2, which is -1 except at n=1
#
#    A066861 steps x/2 and (3x+1)/2
#    A058633 steps of n cumulative
#    A070975 steps for n prime
#    A075677 one reduction 3x+1/2^r on the odd numbers, r as big as possible
#    A014682 one step 3x+1 or x/2 on the integers
#    A006884 new record for highest point reached in iteration
#    A006885   that record high position
#
#    A102419 "dropping time" steps to go below initial
#    A217934 new highs of dropping time steps to go below initial
#    A060412 n where those highs occur
#
#    A074473 "dropping time" + 1, counting initial as step 1
#    A075476 "dropping time" of numbers 64n+7
#    A075477 "dropping time" of numbers 64n+15
#    A075478 "dropping time" of numbers 64n+27
#    A075480 "dropping time" of numbers 64n+39
#    A075481 "dropping time" of numbers 64n+47
#    A075482 "dropping time" of numbers 64n+59
#    A075483 "dropping time" of numbers 64n+63
#    A060445 "dropping time" of odd numbers 2n+1
#    A060412 n start for new record "dropping time"
#    A217934 new record "dropping time"
#
#    A005184 multiple k*n occurs in Collatz trajectory
#    A055509 number of odd primes in trajectory
#    A055510 largest odd prime in trajectory
#    A060322 how many integers have steps=n
#    A070917 steps is a divisor of n
#
#    A088975 collatz tree breadth-first
#    A088976 collatz tree breadth-first
#    A127824 breadth first sorted within rows
#
my %oeis_anum =
  ('one,all,both' => 'A006577',
   'one,all,up'   => 'A006667', # triplings
   'one,even,up'  => 'A006667', # triplings unchanged by even 2*i
   'one,all,down' => 'A006666', # halvings
   # OEIS-Catalogue: A006577
   # OEIS-Catalogue: A006667 step_type=up
   # OEIS-Other:     A006667 step_type=up on_values=even
   # OEIS-Catalogue: A006666 step_type=down

   'one,even,both'  => 'A008908', # +1 from "all"
   'one,all,both+1' => 'A008908', # +1 from "all"
   # OEIS-Catalogue: A008908 on_values=even
   # OEIS-Other:     A008908 step_type=both+1

   'one,odd,both+1' => 'A064685',
   'one,odd1,down' => 'A166549',
   # OEIS-Catalogue: A064685 on_values=odd step_type=both+1
   # OEIS-Catalogue: A166549 on_values=odd1 step_type=down

   # A075680 up steps for odd 2n-1   0,2,1,5,6,4,etc starting n=1 2n-1=1
   # it being defined as steps of (3x+1)/2^r for maximum r
   'one,odd1,up' => 'A075680',
   # OEIS-Catalogue: A075680 on_values=odd1 step_type=up

   #--------------
   # drop

   'drop,all,both'   => 'A102419', # "dropping time"
   'drop,all,both+1' => 'A074473', # "dropping time"
   'drop,all,down'   => 'A126241',
   # OEIS-Catalogue: A102419 end_type=drop
   # OEIS-Catalogue: A074473 end_type=drop step_type=both+1
   # OEIS-Catalogue: A126241 end_type=drop step_type=down

   'drop,odd,both' => 'A060445',  # odd numbers 2n+1 so n=0 for odd=1
   'drop,odd,up'   => 'A122458',
   # OEIS-Catalogue: A060445 end_type=drop on_values=odd
   # OEIS-Catalogue: A122458 end_type=drop on_values=odd step_type=up

   # Not quite A087225 is "position" of peak reckoning start as position=1
   # as opposed to value=0 many "steps" here.
   'to_peak,all,both+1' => 'A087225',
   # OEIS-Catalogue: A087225 end_type=to_peak step_type=both+1

   #--------------
   # pow2

   'pow2,all,both' => 'A208981',
   # OEIS-Catalogue: A208981 end_type=pow2
  );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{"$self->{'end_type'},$self->{'on_values'},$self->{'step_type'}"};
}

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'end_type'} ||= 'one';
  return $self;
}

use constant 1.02 _UV_LIMIT => do {  # version 1.02 for leading underscore
  my $limit = ~0;
  my $bits = 0;
  while ($limit) {
    $bits++;
    $limit >>= 1;
  }
  $bits -= 2;
  (1 << $bits) - 1
};

sub ith {
  my ($self, $i) = @_;
  ### CollatzSteps ith(): $i
  ### end_type: $self->{'end_type'}

  if ($self->{'on_values'} eq 'odd') {
    $i = 2*$i+1;  # i=0 is odd number 1
  } elsif ($self->{'on_values'} eq 'odd1') {
    $i = 2*$i-1;  # i=1 is odd number 1
  } elsif ($self->{'on_values'} eq 'even') {
    $i *= 2;
  }
  my $orig_i = $i;

  my $ups = 0;
  my $downs_sans_trailing = 0;
  my $downs = 0;
  my $peak_ups = 0;
  my $peak_downs = 0;
  if ($i >= 2) {
    if (_is_infinite($i)) {
      return $i;
    }

    my $peak_i = $i;
    my $end = ($self->{'end_type'} eq 'drop' ? $i : 1);

  OUTER: for (;;) {
      $downs_sans_trailing = $downs;
      until ($i & 1) {
        $i >>= 1;
        $downs++;
        last OUTER if $i <= $end;
      }
      ### odd: $i

      if ($i > _UV_LIMIT) {
        $i = Math::NumSeq::_to_bigint($i);

        ### using bigint: "$i"
        for (;;) {
          ### odd: "$i"
          $i->bmul(3);
          $i->binc();
          $ups++;

          if ($i > $peak_i) {
            $peak_ups = $ups;
            $peak_downs = $downs;
            $peak_i = $i;
          }

          $downs_sans_trailing = $downs;
          until ($i->is_odd) {
            $i->brsft(1);
            $downs++;
            last OUTER if $i <= $end;
          }
        }
      }

      $i = 3*$i + 1;
      $ups++;

      if ($i > $peak_i) {
        $peak_ups = $ups;
        $peak_downs = $downs;
        $peak_i = $i;
      }
    }
  }

  ### $ups
  ### $downs
  ### $downs_sans_trailing

  if ($self->{'end_type'} eq 'to_peak') {
    $ups = $peak_ups;
    $downs = $peak_downs;
  } elsif ($self->{'end_type'} eq 'from_peak') {
    $ups -= $peak_ups;
    $downs -= $peak_downs;
  } elsif ($self->{'end_type'} eq 'pow2') {
    $downs = $downs_sans_trailing;
  }

  my $step_type = $self->{'step_type'};
  if ($step_type eq 'up') {
    return $ups;
  }
  if ($step_type eq 'down') {
    return $downs;
  }
  if ($step_type eq 'diff') {
    return $downs - $ups;
  }
  if ($step_type eq 'completeness') {
    # maximum C(N) < ln(2)/ln(3) = 0.63
    return $ups / $downs;
  }
  if ($step_type eq 'gamma') {
    return $downs / (log($orig_i) || 1);
  }
  if ($step_type eq 'residue') {
    # log(Res(N)) = Odd(N)*log(3) - Even(N)*log(2) + log(N)
    return $ups*log(3) - $downs*log(2) + log($orig_i);
  }
  if ($step_type eq 'both+1') {
    return $ups + $downs + 1;
  }
  # $step_type eq 'both'
  return $ups + $downs;
}

sub pred {
  my ($self, $value) = @_;
  return ($value == int($value)
          && $value >= $self->values_min);
}

1;
__END__

=for stopwords Ryde Math-NumSeq Collatz

=head1 NAME

Math::NumSeq::CollatzSteps -- steps in the "3n+1" problem

=head1 SYNOPSIS

 use Math::NumSeq::CollatzSteps;
 my $seq = Math::NumSeq::CollatzSteps->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The number of steps it takes to reach 1 by the Collatz "3n+1" problem,

    0, 1, 7, 2, 5, 8, 16, 3, 19, 6, 14, 9, 9, 17, 17, 4, 12, 20, ...
    starting i=1

The Collatz problem iterates

    n -> / 3n+1  if n odd
         \ n/2   if n even

For example i=6 takes value=8 many steps to reach 1,

    6 -> 3 -> 10 -> 5 -> 16 -> 8 -> 4 -> 2 -> 1

It's conjectured that any starting n will always eventually reduce to 1 and
so the number of steps is finite.  There's no limit in the code on how many
steps counted.  C<Math::BigInt> is used if 3n+1 steps go past the usual
scalar integer limit.

=head2 Up Steps

Option C<step_type =E<gt> "up"> counts only the 3n+1 up steps.

    step_type => "up"
    0, 0, 2, 0, 1, 2, 5, 0, 6, 1, 4, 2, 2, 5, 5, 0, 3, 6, 6, 1, 1, ...

This can also be thought of as steps iterating

    n -> (3n+1)/2^k  for maximum k

=head2 Down Steps

Option C<step_type =E<gt> "down"> counts only the n/2 down steps.

    step_type => "down"
    0, 1, 5, 2, 4, 6, 11, 3, 13, 5, 10, 7, 7, 12, 12, 4, 9, 14, ...

The total up+down gives the default "step_type=both".

=head2 Odd Numbers

Option C<on_values =E<gt> "odd"> counts steps on the odd numbers 2*i+1.

    on_values => "odd"
    0, 7, 5, 16, 19, 14, 9, 17, 12, 20, 7, 15, 23, 111, 18, 106, ...
    starting i=0 for odd number 1

=head2 Even Numbers

Option C<on_values =E<gt> "even"> counts steps on the even number 2*i,

    on_values => "even"
    1, 2, 8, 3, 6, 9, 17, 4, 20, 7, 15, 10, 10, 18, 18, 5, 13, 21, ...
    starting i=0 for even number 2

Since 2*i is even the first step is down n/2 to give i and thereafter the
same as the plain count.  This means the steps for "even" is simply 1 more
than for plain "all".

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::CollatzSteps-E<gt>new ()>

=item C<$seq = Math::NumSeq::CollatzSteps-E<gt>new (step_type =E<gt> $str, on_values =E<gt> $str)>

Create and return a new sequence object.  The optional C<step_type>
parameter (a string) can be

    "up"      upward steps 3n+1
    "down"    downward steps n/2
    "both"    both up and down (the default)

The optional C<on_values> parameter (a string) can be

    "all"     all integers i
    "odd"     odd integers 2*i+1
    "even"    even integers 2*i

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the number of steps to take C<$i> down to 1.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs as a step count.  This is simply C<$value
E<gt>= 0>.

=cut

# i=2^k steps down n->n/2
# n odd n -> 3n+1 want == 2 mod 4
# 3n+1 == 2 mod 4
# 3n == 1 mod 4
# 3*1=3 3*2=6 3*3=9
# so n == 3 mod 4
# 4k+3 is odd -> 3*(4k+3)+1 = 12k+8 -> 3k+2
# 3k+2 == 1 mod 4
# 2,5,8,11  k=4j+1
# 3(4j+1)+2 = 12j+5

=pod

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::JugglerSteps>,
L<Math::NumSeq::ReverseAddSteps>
L<Math::NumSeq::HappySteps>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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
