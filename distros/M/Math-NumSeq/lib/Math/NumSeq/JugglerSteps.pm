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

package Math::NumSeq::JugglerSteps;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');

use Math::NumSeq::Base::Cache
  'cache_hash',
  'make_key';

# uncomment this to run the ### lines
#use Devel::Comments;

# use constant name => Math::NumSeq::__('Juggler Steps');
use constant description => Math::NumSeq::__('Number of steps to reach 1 in the Juggler sqrt sequence.');
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;
use constant values_min => 0;
use constant i_start => 1;

use constant parameter_info_array =>
  [
   { name    => 'step_type',
     display => Math::NumSeq::__('Step Type'),
     type    => 'enum',
     default => 'both',
     choices => ['up','down','both'],
     choices_display => [Math::NumSeq::__('Up'),
                         Math::NumSeq::__('Down'),
                         Math::NumSeq::__('Both'),
                        ],
     description => Math::NumSeq::__('Which steps to count, the n^(3/2) ups, the n^(1/2) downs, or both.'),
   },
   { name    => 'juggler_type',
     display => Math::NumSeq::__('Juggler Algorithm Type'),
     type    => 'string',
     default => '1/2-3/2',
     width   => 9,
     choices => ['1/2-3/2','2/3-3/2','3/4-4/3'],
     description => Math::NumSeq::__('Juggler algorithm type, as the even power and odd power.'),
   },
   # { name    => 'round_type',
   #   display => Math::NumSeq::__('Rounding Type'),
   #   type    => 'enum',
   #   default => 'floor',
   #   choices => ['floor','round'],
   # choices_display => [Math::NumSeq::__('Floor'),
   #                     Math::NumSeq::__('Round'),
   #                    ],
   #   description => Math::NumSeq::__('Rounding type.'),
   # },
  ];

#------------------------------------------------------------------------------
# eg. 78901 peaks at about 370,000 digits ...
#
# cf
#    A094683 - iteration, ie. n^(1/2) or n^(3/2)
#    A094670 - smallest requiring n iterations
#    A094679 - start requiring n iterations
#    A094684 - records in plain seq
#    A094698 - num steps where new record
#    A143745 - next largest
#    A094716 - largest value in trajectory starting from n
#    A094778 - dropping time from odd
#    A094804 - num primes in trajectory
#    A094819 - steps starting 10^n
#    A143742 - producing larger value
#    A143743 - num digits
#    A143744 - steps next largest
#
#    A007321 - rounded steps
#    A094685 - rounded iteration, ie. single powering
#    A094693 - rounded records
#    A094725 - rounded largest value in trajectory starting from n
#    A095910 - rounded records
#    A095911 - rounded num steps to records
#
#    A095396 - 2/3-3/2 iteration
#    A095397 - 2/3-3/2 largest in trajectory starting from n
#    A095398 - 2/3-3/2 steps
#
#    A095399 - 3/4-4/3 iteration
#    A095400 - 3/4-4/3 largest value in trajectory starting from n
#    A095401 - 3/4-4/3 steps
#
# up   => '',
# # OEIS-Catalogue:  step_type=up
#
# down => '',
# # OEIS-Catalogue:  step_type=down
#
my %oeis_anum = (
                 # both up and down
                 both => { '1/2-3/2' => 'A007320',
                           # OEIS-Catalogue: A007320

                           '2/3-3/2' => 'A095398',
                           # OEIS-Catalogue: A095398 juggler_type=2/3-3/2

                           '3/4-4/3' => 'A095401',
                           # OEIS-Catalogue: A095401 juggler_type=3/4-4/3
                         },
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'step_type'}}->{$self->{'juggler_type'}};
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  ($self->{'epow'},$self->{'eroot'}, $self->{'opow'},$self->{'oroot'})
    = ($self->{'juggler_type'} =~ m{(\d+)/(\d+)-(\d+)/(\d+)});
  $self->{'i'} = i_start();
}

use constant 1.02;  # for leading underscore
use constant _UV_3_2_LIMIT => do {
  my $limit = ~0;
  my $bits = 0;
  while ($limit) {
    $bits++;
    $limit >>= 1;
  }
  $bits = int($bits / 3);
  (1 << $bits) - 1
};

my %cache_upto;
sub next {
  my ($self) = @_;
  ### JugglerSteps next(): $self->{'i'}

  my $i = $self->{'i'}++;
  my $pkey = ($self->{'pkey'} ||= do {
    ### make pkey ...
    my $k = make_key('JugglerSteps',
                     $self->{'juggler_type'},
                     $self->{'step_type'});
    $cache_upto{$k} ||= 0;
    $k
  });
  my $key_i = $pkey . $i;

  ### $pkey
  ### $key_i
  ### cache upto: "$cache_upto{$pkey} cf i=$i"

  if ($i < $cache_upto{$pkey}) {
    ### fetch from cache ...
    return ($i, cache_hash()->{$key_i});
  } else {
    ### store to cache ...
    my $ret = $self->ith($i);
    cache_hash()->{$key_i} = $ret;
    $cache_upto{$pkey} = $i;
    ### cache upto now: $cache_upto{$pkey}
    return ($i, $ret);
  }
}

sub ith {
  my ($self, $i) = @_;
  ### JugglerSteps ith(): $i
  my $count = 0;
  if ($i <= 1) {
    return $count;
  }

  my $pkey = $self->{'pkey'};
  my $step_type = $self->{'step_type'};
  my $count_up = ($step_type ne 'down');
  my $count_down = ($step_type ne 'up');
  my %seen;

  if ($self->{'juggler_type'} eq '1/2-3/2') {
    ### 1/2 and 3/2 ...
    for (;;) {
      if ($pkey && $i < $cache_upto{$pkey}) {
        my $c = cache_hash()->{$pkey.$i};
        ### from cache: "$c at i=$i"
        if ($c < 0) {
          return $c;
        } else {
          return $c + $count;
        }
      }

      if ($i & 1) {
        ### 1/2 odd: $i

        if ($i > _UV_3_2_LIMIT) {
          $i = Math::NumSeq::_to_bigint($i);
          ### using bigint: "$i"
          for (;;) {
            if ($pkey && $i < $cache_upto{$pkey}) {
              my $c = cache_hash()->{$pkey.$i};
              ### from cache: "$c at i=$i"
              if ($c < 0) {
                return $c;
              } else {
                return $c + $count;
              }
            }

            if ($i & 1) {
              ### 1/2 odd: "$i"
              $i->bmul($i*$i);
              $count += $count_up;
            } else {
              ### 1/2 even: "$i"
              $count += $count_down;
            }
            $i->bsqrt();
            if ($i <= 1) {
              return $count;
            }
            ### now: "$i  count=$count"
            if ($seen{$i}++) {
              ### repeat of bigint: $i
              return -1;
            }
          }
        }

        $i *= $i*$i;
        $count += $count_up;
      } else {
        ### even: $i
        $count += $count_down;
      }
      $i = int(sqrt($i));
      if ($i <= 1) {
        return $count;
      }
      ### now: "$i  count=$count"
      if ($seen{$i}++) {
        return -1;
      }
    }

  } else {
    ### general case: "$self->{'epow'}/$self->{'eroot'}-$self->{'opow'}/$self->{'oroot'}"
    $i = Math::NumSeq::_to_bigint($i);

    unless (($self->{'opow'} % $self->{'oroot'})
            && ($self->{'epow'} % $self->{'eroot'})) {
      return -1;
    }

    for (;;) {
      if ($pkey && $i < $cache_upto{$pkey}) {
        my $c = cache_hash()->{$pkey.$i};
        ### from cache: "$c at i=$i"
        if ($c < 0) {
          return $c;
        } else {
          return $c + $count;
        }
      }

      if ($i->is_odd) {
        ### odd: "$i"
        $i->bpow($self->{'opow'});
        $i->broot($self->{'oroot'});
        $count += $count_up;
      } else {
        ### even: "$i"
        $i->bpow($self->{'epow'});
        $i->broot($self->{'eroot'});
        $count += $count_down;
      }
      if ($i <= 1) {
        return $count;
      }
      ### now: "$i  count=$count"
      if ($seen{$i}++) {
        ### repeat of: $i
        return -1;
      }
    }
  }
}

sub pred {
  my ($self, $value) = @_;
  return ($value == int($value)
          && $value >= 0);
}

1;
__END__

=for stopwords Ryde Math-NumSeq sqrt

=head1 NAME

Math::NumSeq::JugglerSteps -- steps in the juggler sqrt sequence

=head1 SYNOPSIS

 use Math::NumSeq::JugglerSteps;
 my $seq = Math::NumSeq::JugglerSteps->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the number of steps it takes to reach 1 by the Juggler sqrt
sequence,

    n ->  /  floor(n^(1/2))      if n even
          \  floor(n^(3/2))      if n odd

So sqrt if n even, or sqrt(n^3) if n odd, each rounded downwards.  For
example i=17 goes 17 -> sqrt(17^3)=70 -> sqrt(70)=8 -> sqrt(8)=2 ->
sqrt(2)=1, for a count of 4 steps.

    0, 1, 6, 2, 5, 2, 4, 2, 7, 7, 4, 7, 4, 7, 6, 3, 4, 3, 9, 3, ...
    starting i=1

The intermediate values in the calculation can become quite large and
C<Math::BigInt> is used if necessary.  There's some secret experimental
caching in a temporary file, for a small speedup.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::JugglerSteps-E<gt>new ()>

=item C<$seq = Math::NumSeq::JugglerSteps-E<gt>new (step_type =E<gt> 'both', juggler_type =E<gt> '1/2-3/2')>

Create and return a new sequence object.

The optional C<step_type> parameter (a string) selects between

    "up"      upward steps sqrt(n^3)
    "down"    downward steps sqrt(n)
    "both"    both up and down, which is the default

The optional C<juggler_type> parameter (a string) selects among variations
on the powering

                  n even        n odd
    "1/2-3/2"    sqrt(n)   and sqrt(n^3)
    "2/3-3/2"    cbrt(n^2) and sqrt(n^3)
    "3/4-4/3"    n^(3/4)   and n^(4/3)

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the number of steps to take C<$i> down to 1.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs as a step count.  This is simply C<$value
E<gt>= 0>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::CollatzSteps>,
L<Math::NumSeq::ReverseAddSteps>

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
