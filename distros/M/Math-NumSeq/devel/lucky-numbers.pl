#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use POSIX;
use List::Util 'max','min';

# uncomment this to run the ### lines
# use Smart::Comments;





{
  # speed
  require Devel::TimeThis;
  my $iterations = 5000;
  # {
  #   my $self = { values    => [ 7 ],
  #                value     => 7,
  #                i         => 1,
  #                remaining => [ 4 ],
  #                inc       => 4,
  #              };
  #   my $t = Devel::TimeThis->new('subs');
  #   foreach (1 .. $iterations) {
  #     &next($self);
  #   }
  # }
  # {
  #   require Math::NumSeq::LuckyNumbersSlow;
  #   my $seq = Math::NumSeq::LuckyNumbersSlow->new;
  #   my $t = Devel::TimeThis->new('slow');
  #   foreach (1 .. $iterations) {
  #     $seq->next;
  #   }
  # }
  {
    require Math::NumSeq::LuckyNumbers;
    my $seq = Math::NumSeq::LuckyNumbers->new;
    if ($seq->can('ith')) {
      my $t = Devel::TimeThis->new('ith');
      foreach (1 .. $iterations) {
        $seq->ith($_);
      }
      ### $seq
    }
  }
  {
    require Math::NumSeq::LuckyNumbers;
    my $seq = Math::NumSeq::LuckyNumbers->new;
    my $t = Devel::TimeThis->new('seq');
    foreach (1 .. $iterations) {
      $seq->next;
    }
    ### $seq
  }
  {
    require Math::NumSeq::LuckyNumbersByStep;
    my $seq = Math::NumSeq::LuckyNumbersByStep->new;
    my $t = Devel::TimeThis->new('step');
    foreach (1 .. $iterations) {
      $seq->next;
    }
    ### $seq
  }
  {
    require '../backup/DanaLuckyNumbers.pm';
    my $seq = Math::NumSeq::DanaLuckyNumbers->new;
    my $t = Devel::TimeThis->new('array');
    foreach (1 .. $iterations) {
      $seq->next;
    }
    ### $seq
  }
  exit 0;
}

{
  require Math::NumSeq::LuckyNumbers;
  require Math::NumSeq::OEIS::File;
  my $seq = Math::NumSeq::LuckyNumbers->new;
  my $file = Math::NumSeq::OEIS::File->new (anum => 'A000959');
  for (;;) {
    my ($got_i, $got_value) = $seq->next;
    my ($file_i, $file_value) = $file->next
      or do {
        print "ok to $got_i\n";
        last;
      };
    if ($got_i != $file_i) {
      die; 
    }
    if ($got_value != $file_value) {
      die; 
    }
  }
  exit 0;
}


{
  my @want = (undef,1,3,7,9,13,15,21,25,31,33,37,43,49,51,63,67,69,73,75,
              79,87,93,99,105,111,115,127,129,133,135,141,151,159,163,
              169,171,189,193,195,201,205,211,219,223,231,235,237,241,
              259,261,267,273,283,285,289,297,303);

  # 1 2   3 4
  # 1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,...
  # 1,3,  7,9,   13,15,   19,21,   25,27,   31,33,   37,39,...  3s
  # 1,3,  7,9,   13,15,      21,   25,27,   31,33,   37,   ...  7s exclude 19..
  # 1,3,  7,9,   13,15,      21,   25,      31,33,   37,   ...  9s exclude 27..

  require Math::NumSeq::LuckyNumbers;
  my $seq = Math::NumSeq::LuckyNumbers->new;
  # print $seq->ith(20),"\n";
  # my $seq = {
  #            };
  #foreach (1 .. 33) {
  foreach (1 .. $#want) {
    my ($i,$value) = $seq->next;
    my $bad = (defined $value && $value == $want[$i] ? '' : "  *** want=$want[$i]");
    print "i=$i value=$value$bad\n";

    # $value = $seq->ith($i);
    # $bad = (defined $value && $value == $want[$i] ? '' : '  ****');
    # print "  ith($i) value=$value$bad\n";
  }
  # use Smart::Comments;
  # no Smart::Comments;
}

{
  # speed of sieve
  require Time::HiRes;
  $| = 1;

  my @want = (1,3,7,9,13,15,21,25,31,33,37,43,49,51,63,67,69,73,75,
              79,87,93,99,105,111,115,127,129,133,135,141,151,159,163,
              169,171,189,193,195,201,205,211,219,223,231,235,237,241,
              259,261,267,273,283,285,289,297,303);

  my $prev_t = 1;
  for (my $len = 2; $len < 500000; $len = ceil($len * 1.05)) {
    my @array;
    for (my $i = 1; @array < $len; $i += 2) {
      push @array, $i;
    }

    my $t = Time::HiRes::time();
    for (my $i = 1; $i < @array; $i++) {
      ### at: "i=$i array=".join(',',@array)
      my $m = $array[$i] - 1;
      last if $m >= @array;

      for (my $f = $m; $f < @array; $f += $m) {
        ### $f
        splice @array, $f, 1;
      }
    }
    $t = Time::HiRes::time() - $t;

    my $factor = $t / $prev_t;
    # print "$len $t  $factor\n";
    print "$len $t\n";
    $prev_t = $t;

    for (my $i = 0; $i <= $#want && $i <= $#array; $i++) {
      if ($array[$i] != $want[$i]) {
        die "wrong";
      }
    }
  }
  exit 0;
}




{
  # count of trailing monotonic remainders
  require Math::NumSeq::LuckyNumbers;
  my $seq = Math::NumSeq::LuckyNumbers->new;
  my $remaining = $seq->{'remaining'};
  foreach (1 .. 5000) {
    my ($i,$value) = $seq->next;
    # print join(',',@$remaining),"\n";
    my $rlen = scalar(@$remaining);
    my $found = 0;
    my $prev = $remaining->[-2];
    for (my $pos = $#$remaining-2; $pos >= 0; $pos--) {
      my $this = $remaining->[$pos];
      if ($this >= $prev) {
        $found = $pos;
        last;
      }
      $prev = $this;
    }
    if ($i % 100 == 0) {
      my $estimate_found = $i/log($i) / .96;

      printf "%3d  %5d   mono %d/%d  %.3f   %.3f\n",
        $i,$value, $found, $rlen, $found/$rlen, $estimate_found/$found;
    }
  }
  exit 0;
}




{
  # to value=55
  require Math::NumSeq::LuckyNumbers;
  my $seq = Math::NumSeq::LuckyNumbers->new;
  for (;;) {
    my ($i,$value) = $seq->next;
    last if $value > 55;
  }
  exit 0;
}


=head1 FORMULAS

=head2 Next

The initial multiple-of-3
exclusions are done by adding either 2 or 4 alternately to the candidate
return value
   
    value += (increment ^= 6)     # increment=2 or 4 alternately

Further multiple-of-N exclusions are applied by a table of remaining counts,
starting from multiple-of-7.  For example when up to considering value=55,

    # about to consider value=55
    multiple     7   9   13   15  ...
    remaining    3   2   11    1  ...

This means multiple-of-7 exclusion is 3 values away.  The candidate value=55
is passed and the counter decreases to 2.  Likewise multiple-of-9 and
multiple-of-13 decrement.  But the multiple-of-15 is down to 1 left, which
means value=55 is excluded and the counter resets to 15 again.

    # after value=55 excluded
    multiple     7   9   13   15   21
    remaining    2   1   10   15    7

As an optimization, it's not necessary to keep the counters of all
previously generated values, only up to the first which not yet excluded
anything.  In this example the full set of counters up to the value=51
previously generated would have been

    # after value=55 excluded, full set of counters
    multiple     7   9   13   15   21   25  31  33  37  43  49  51
    remaining    2   1   10   15    7   11  17  19  23  29  35  37

Notice that from multiple-of-21 onwards the remaining counts are always
increasing.  That's because for example a multiple-of-25 will not exclude
anything until multiple-of-21 does.

At value=55 the multiple-of-15 reached zero for the first time.  So at that
point multiple-of-21 is appended.  Its initial value is 21-(15-1) because
the multiple-of-15 has passed 15-1=14 previous values, so they are
subtracted from the initial multiple-of-21 count.  In general a new counter
is appended whenever the end-most counter reaches zero.

When appending a new counter there's no need to save all the values
generated to know what multiple it should be, instead maintain a sub-table
of multiples and remainders to generate the sequence values at that point.
A single sub-level like this is enough because within that sub-level the
top-level "multiples" list is long enough to take the new multiples counts
appended in the sub-level.

After generating i many values the array length satisfies ith(len)=i,
ie. value_to_ith(i).  As noted above values increase like the primes
x/log(x) and the array is roughly

    len = i/log(i) * 1.04       after generating i many values

In practice means roughly 1/6 to 1/8 of what the full set of values would
have been.  The smaller array is much faster to run through and decrement
when considering a candidate return value.

=cut

# after k many values value_to_i(k)
# i ~= value/log(value)
# value_to_i(k) = k/log(k)





{
  # sieve stages
  my @sieve = (map { 2*$_+1} 0 .. 100); # odd 1,3,5,7 etc
  for (my $upto = 1; $upto <= $#sieve; $upto++) {
    my $str = join(',',@sieve);
    $str = substr($str,0,70);
    print "$str\n";

    my $step = $sieve[$upto];
    ### $step
    for (my $i = $step-1; $i <= $#sieve; $i += $step-1) {
      splice @sieve, $i, 1;
    }
  }
  exit 0;
}




__END__


  # $self->{'value'}   = 7;
  # $self->{'count'}   = [ 3 ];
  # $self->{'threes'}  = 0;
  $self->{'pos'}     = 0;
  $self->{'mod_i'}   = 4;

my @small = (undef, 1, 3, 7);

  }

  {
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
    ### increased i with ones: $i

    if ($i > 2*$mod->[$two_pos]) {
      ### advance two ...
      $self->{'two_pos'} = ++$two_pos;
      $i--;
    }
    return ($ret_i,
            _ith_by_mod($mod, $i, $two_pos));
  }

  {
    ### LuckyNumbers next(): "i=$self->{'i'}"
    my $i = $self->{'i'}++;
    my $pos = $self->{'pos'};
    if ($i > $self->{'mod'}->[$pos]) {
      ### extend mod array ...
      $self->{'pos'} = ++$pos;

      my $mod_i = $self->{'mod_i'}++;
      my $mod_pos = $self->{'mod_pos'};
      if ($mod_i >= $self->{'mod'}->[$mod_pos]) {
        $self->{'mod_pos'} = ++$mod_pos;
      }
      $self->{'mod'}->[$pos] = _ith_from_pos($self, $mod_i, $mod_pos) - 1;
      ### new_mod: $self->{'mod'}->[$pos]
      ### store to: "pos=$pos"
    }
    return ($i,
            _ith_from_pos($self, $i-1, $pos));
  }

  {
    my $i = $self->{'i'}++;
    my $pos = $self->{'pos'};
    if ($i > $self->{'mod'}->[$pos]) {
      ### extend mod array ...
      $self->{'pos'} = ++$pos;

      my $mod_i = $self->{'mod_i'}++;
      my $mod_pos = $self->{'mod_pos'};
      if ($mod_i >= $self->{'mod'}->[$mod_pos]) {
        $self->{'mod_pos'} = ++$mod_pos;
      }
      $self->{'mod'}->[$pos] = _ith_from_pos($self, $mod_i, $mod_pos) - 1;
      ### new_mod: $self->{'mod'}->[$pos]
      ### store to: "pos=$pos"
    }
    return ($i,
            _ith_from_pos($self, $i-1, $pos));
  }


  {
    my $i = $self->{'i'}++;
    if ($i <= $#small) {
      ### small: $small[$i]
      return ($i, $small[$i]);
    }

    ### mod  : join(', ',@{$self->{'mod'}})
    ### count: join(', ',@{$self->{'count'}})

    my $mod = $self->{'mod'};
    my $count = $self->{'count'};
    my $inc = 1;
    {
      my $pos = scalar(@$count);
      for ( ; $pos--; ) {
        if (($count->[$pos] -= $inc) < 0) {
          ### underflow, reset ...
          $count->[$pos] += $mod->[$pos];

          if (++$inc > 6) {
            while ($pos--) {
              my $c = $count->[$pos] - $inc;
              $inc -= ($c - ($count->[$pos] = $c % $mod->[$pos])) / $mod->[$pos];
            }
            last;
          }
        }
      }
    }

    ### mod      : join(', ',@{$self->{'mod'}})
    ### new count: join(', ',@$count)

    unless ($count->[-1]) {
      my $pos = scalar(@$count);
      ### last wrapped, extend: "pos=$pos"

      my $new_mod;
      if ($pos <= $#$mod) {
        $new_mod = $mod->[$pos];
      } else {
        ### extend mod array ...
        my $mod_i = $self->{'mod_i'}++;
        my $mod_pos = $self->{'mod_pos'};
        if ($mod->[$mod_pos] <= $mod_i) {
          $self->{'mod_pos'} = ++$mod_pos;
        }
        $mod->[$pos] = $new_mod = _ith_from_pos($self, $mod_i, $mod_pos) - 1;
        ### $new_mod
        ### store to: "pos=$pos"
      }
      push @$count, $new_mod - $mod->[$pos-1];
    }

    ### at threes: "inc=$inc threes=$self->{'threes'}"
    {
      my $c = $inc + $self->{'threes'};
      $self->{'threes'} = $c & 1;
      $inc += ($c >> 1);
    }

    ### inc of odd: $inc

    ### return value: $self->{'value'} + 2*$inc
    return ($self->{'i'}++,
            $self->{'value'} += 2*$inc);
  }

sub _ith_from_pos {
  my ($self, $i, $pos) = @_;
  ### LuckyNumbers _ith_from_pos(): "i=$i pos=$pos from mods=".join(',',@{$self->{'mod'}}[0..$pos])

  {
    my $orig_pos = $pos;
    my @dist;
    my $mod = $self->{'mod'};
    while ($pos >= 0) {
      if (int($i / $mod->[$pos]) < 20) {
        $dist[int($i / $mod->[$pos])] = $pos;
      }
      $i += int($i / $mod->[$pos]);
      $pos--;
    }
    my $value = int($i/12)*42 + $twelve[$i%12];
    foreach (@dist) { $_ ||= '' }
    print "$orig_pos($value) dist ",join(',',@dist),"\n";
    return $value;
  }
  {
    my $mod = $self->{'mod'};
    while (--$pos >= 0) {
      $i += int($i / $mod->[$pos]);
    }
    ### result: int($i/12)*21 + $twelve[$i%12]
    return int($i/12)*42 + $twelve[$i%12];
  }
  {
    my $mod = $self->{'mod'};
    do {
      $i += int($i / $mod->[$pos]);
    } while ($pos--);
    ### result: 1 + 2*($i + ($i >> 1))
    return 1 + 2*($i + ($i >> 1));
  }
  {
    my $mod = $self->{'mod'};
    my $orig_i;
    my $add = 0;
    my $prod = $i;
    do {
      my $m = $mod->[$pos];
      if ($i >= $m) {
        if ($i < 2*$m) {
          $i++;
        } else {
          $i += int($i / $m);
        }
      }
    } while ($pos--);
    ### result: 1 + 2*($i + ($i >> 1))
    return 1 + 2*($i + ($i >> 1));
  }
}






# sub ith {
#   my ($self, $i) = @_;
#   ### LuckyNumbers ith(): $i
# 
#   if (_is_infinite($i)) {
#     return $i;
#   }
#   if ($i < 1) {
#     return undef;
#   }
# 
#   my $mod;
#   if ($i <= $#small) {
#     ### small: $small[$i]
#     return $small[$i];
#   }
# 
#   $mod = $self->{'mod'};
#   $i--;
# 
#   my $pos = 0;
#   while ($mod->[$pos] <= $i) {
#     $pos++;
#     if ($pos > $#$mod) {
#       ### extend mods ...
#       my ($mod_i, $value) = &next($self->{'subseq'});
#       $mod->[$mod_i-3] = $value-1;
#     }
#   }
# 
#   for ( ; $pos >= 0; $pos--) {
#     $i += int($i / $mod->[$pos]);
#   }
# 
#   return 1 + 2*($i + ($i >> 1));
# }


# stepwise incr

# sub rewind {
#   my ($self) = @_;
#   $self->{'i'}             = $self->i_start;
#   $self->{'remaining'}     = [ 4 ];
#   $self->{'subseq'}->{'i'} = 4;
#   $self->{'subseq'}->{'inc'}       = $self->{'inc'}    = 4;
#   $self->{'subseq'}->{'values'}    = $self->{'values'} = [ 7 ];  # shared
#   $self->{'subseq'}->{'value'}     = $self->{'value'}  = 7;
#   $self->{'subseq'}->{'remaining'} = [ 4 ];
# }
# 
# my @small = (undef, 1, 3, 7);
# sub next {
#   my ($self) = @_;
#   ### LuckyNumbers next(): "i=$self->{'i'}"
# 
#   my $values;
#   {
#     my $i = $self->{'i'};
#     if ($i <= $#small) {
#       ### small: $small[$i]
#       return ($self->{'i'}++, $small[$i]);
#     }
# 
#     $values = $self->{'values'};
#     if (($i -= 3) <= $#$values) {   # i=3 value=7
#       ### values array: $values->[$i]
#       return ($self->{'i'}++, $values->[$i]);
#     }
#   }
# 
#   my $remaining = $self->{'remaining'};
#   my $value = $self->{'value'};
# 
#  OUTER: for (;;) {
#     $value += ($self->{'inc'} ^= 6);  # 2 or 4 alternately
# 
#     ### at remaining: join(', ',@$remaining)
#     ### values      : join(', ',@{$self->{'values'}})
#     ### consider value: $value
# 
#     foreach my $pos (0 .. $#$remaining - 1) {
#       if (--$remaining->[$pos] <= 0) {
#         ### exclude at: "pos=$pos  mults value=$self->{'values'}->[$pos]"
#         $remaining->[$pos] = $self->{'values'}->[$pos]; # reset
#         next OUTER;
#       }
#     }
# 
#     if (--$remaining->[-1] <= 0) {
#       ### exclude at last: "pos=$#$remaining  mults value=$self->{'values'}->[$#$remaining]"
#       # restart last counter
#       my $reset = $remaining->[-1] = $self->{'values'}->[$#$remaining];
# 
#       my $sub_value;
#       my $pos = scalar(@$remaining);
#       if ($pos <= $#$values) {
#         $sub_value = $values->[$pos];
#       } else {
#         (my $sub_i, $sub_value) = &next($self->{'subseq'});
#       }
# 
#       ### $sub_value
#       $self->{'values'}->[$pos] = $sub_value;
#       $self->{'remaining'}->[$pos] = $sub_value - $reset + 1;
#       next;
#     }
# 
#     $self->{'value'} = $value;
#     return ($self->{'i'}++,
#             $value);
#   }
# }



  # while (--$three_pos >= 0) {
  #   $i += int($i / $mod->[$three_pos]);
  # }
  # ### final: "i=$i  result=".(int($i/12)*21 + $twelve[$i%12])
  # return ($ret_i,
  #         int($i/12)*42 + $twelve[$i%12]);
  # 
  # 
  # 
  # foreach my $pos (reverse 0 .. $three_pos-1) {
  #   ### at: "pos=$pos i=$i"
  #   $i += int($i / $mod->[$pos]);
  # }
  # ### final: "i=$i  result=".(int($i/12)*21 + $twelve[$i%12])
  # return ($ret_i,
  #         int($i/12)*42 + $twelve[$i%12]);


