#!/usr/bin/perl -w

# Copyright 2012, 2013, 2018, 2019 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


# cf A057163 tree reflection left-right mirror image
#            ordered forest diagonal flip
#    A075166 A106456 tree by prime powers
# A079214 catalan digit changes


use 5.004;
use strict;
use Math::BigInt;
use Math::BaseCnv 'cnv';

use Test;
plan tests => 24;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::BalancedBinary;

use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;

use Math::NumSeq::RadixConversion;
*_digit_join_lowtohigh = \&Math::NumSeq::RadixConversion::_digit_join_lowtohigh;

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# A085192 first diffs

# differences xor
# not in OEIS: 2,8,6,38,6,30,6,12,146,6,30,6,12,114,6,30
# not in OEIS: 10,1000,110,100110,110,11110,110,1100,10010010,110,11110,110,1100

MyOEIS::compare_values
  (anum => 'A085192',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got;
     my $prev = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value - $prev;
       $prev = $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A014138 - cumulative Catalan
# total 0s in highest 0s run of 2n bits

# Return the length of the highest run of 0 bits in $n.
sub highest_0s_run_length {
  my ($n) = @_;
  my $ret = 0;
  for (;;) {
    while ($n & 1) { $n >>= 1; }   # strip low 1s
    $n || last;
    $ret = 0;
    until ($n & 1) { $n >>= 1; $ret++; }   # count and strip low 0s
  }
  return $ret;
}
ok (highest_0s_run_length(cnv(0, 2,10)), 0);
ok (highest_0s_run_length(cnv(1, 2,10)), 0);
ok (highest_0s_run_length(cnv(10, 2,10)), 1);
ok (highest_0s_run_length(cnv(100, 2,10)), 2);
ok (highest_0s_run_length(cnv(10001, 2,10)), 3);
ok (highest_0s_run_length(cnv(111000111, 2,10)), 3);
ok (highest_0s_run_length(cnv(1100101011, 2,10)), 2);

MyOEIS::compare_values
  (anum => 'A014138',
   max_count => 10,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::BalancedBinary->new;
     require Math::NumSeq::DigitLength;
     my $dlen = Math::NumSeq::DigitLength->new (radix => 2);
     my @got;
     my $total = 0;
     my $prev_len = 4;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       my $len = $dlen->ith($value);
       if ($len != $prev_len) {
         ### $len
         ### $total
         push @got, $total;
         $total = 0;
         $prev_len = $len;
       }
       $total += highest_0s_run_length($value);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A002054 - number of 01 bit pairs

MyOEIS::compare_values
  (anum => 'A002054',
   max_count => 10,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::BalancedBinary->new;
     $seq->next;  # skip value=10
     require Math::NumSeq::DigitLength;
     my $dlen = Math::NumSeq::DigitLength->new (radix => 2);
     my @got;
     my $prev_len = 4;
     my $total = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       my $len = $dlen->ith($value);
       if ($len != $prev_len) {
         ### $len
         ### $total
         push @got, $total;
         $total = 0;
         $prev_len = $len;
       }
       $total += count_01($value);
     }
     return \@got;
   });

# Return the number of 01 bit pairs in $n.
sub count_01 {
  my ($n) = @_;
  my $ret = 0;
  while ($n > 1) {
    $ret += (($n & 3) == 1);
    $n >>= 1;
  }
  return $ret;
}


#------------------------------------------------------------------------------
# A080300 - ranking, value -> i or if no such then 0

MyOEIS::compare_values
  (anum => 'A080300',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got;

     for (my $value = 0; @got < $count; $value++) {
       my $i = $seq->value_to_i($value);
       push @got, $i || 0;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A057520 - without low 0-bit, including 0

MyOEIS::compare_values
  (anum => 'A057520',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::DigitLength;
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got = (0);
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $value /= 2;                                 # strip low 0-bit
       push @got, $value;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A085183 - without high,low 1,0 bits

MyOEIS::compare_values
  (anum => 'A085183',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     require Math::NumSeq::DigitLength;
     my $dlen = Math::NumSeq::DigitLength->new (radix => 2);
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $value /= 2;                                 # strip low 0-bit
       my $pos = $dlen->ith($value);
       $value -= Math::BigInt->new(1) << ($pos-1);  # strip high 1-bit
       push @got, $value;
     }
     return \@got;
   });

# A085184 - without high,low 1,0 bits, in base 4
MyOEIS::compare_values
  (anum => 'A085184',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     require Math::NumSeq::DigitLength;
     my $dlen = Math::NumSeq::DigitLength->new (radix => 2);
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $value /= 2;                                 # strip low 0-bit
       my $pos = $dlen->ith($value);
       $value -= Math::BigInt->new(1) << ($pos-1);  # strip high 1-bit
       push @got, to_base4_str($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A085185 - in base4, including 0

MyOEIS::compare_values
  (anum => 'A085185',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got = (0);
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, to_base4_str($value);
     }
     return \@got;
   });

sub to_base4_str {
  my ($n) = @_;
  if ($n == 0) { return '0'; }
  my @digits;
  while ($n) {
    push @digits, ($n&3);
    $n >>= 2;
  }
  return join('',reverse @digits);
}


#------------------------------------------------------------------------------
# A057118 - depth-first -> breadth-first index map
#
# cf A038776 -
#    A070041  # df->bf 1-based

MyOEIS::compare_values
  (anum => 'A057117',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got = (0);
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       my @bits = bit_split_hightolow($value);
       @bits = bits_breadth_to_depth(@bits);
       my $pvalue = bit_join_hightolow(\@bits);
       ### dtob: @bits
       ### $pvalue
       my $pi = $seq->value_to_i($pvalue);
       if (! defined $pi) {
         ### @bits
         die "Oops, bad pvalue $pvalue: ",join('',@bits);
       }
       push @got, $pi;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A057118',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got = (0);
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       my @bits = bit_split_hightolow($value);
       @bits = bits_depth_to_breadth(@bits);
       my $pvalue = bit_join_hightolow(\@bits);
       ### dtob: @bits
       ### $pvalue
       my $pi = $seq->value_to_i($pvalue);
       if (! defined $pi) {
         ### @bits
         die "Oops, bad pvalue $pvalue: ",join('',@bits);
       }
       push @got, $pi;
     }
     return \@got;
   });

sub bit_split_hightolow {
  my ($n) = @_;
  return reverse _digit_split_lowtohigh($n,2);
}
sub bit_join_hightolow {
  my ($aref) = @_;
  return _digit_join_lowtohigh([reverse @$aref],2);
}

sub depthfirst_bits_to_tree {
  my @bits = @_;
  ### depthfirst_bits_to_tree(): join('',@bits)
  push @bits, 0;
  my $take;
  $take = sub {
    my $bit = shift @bits;
    if ($bit) {
      my $left = &$take();
      my $right = &$take();
      return [$left,$right];
    } else {
      return 0;
    }
  };
  my $tree = &$take();
  if (@bits) {
    die "Oops, bits left over: ",@bits;
  }
  return $tree;
}
sub depthfirst_tree_to_bits {
  my ($tree) = @_;
  ### depthfirst_bits_to_tree(): $tree
  my $emit;
  $emit = sub {
    my ($part) = @_;
    ### $part
    if ($part) {
      return 1,$emit->($part->[0]),$emit->($part->[1]);
    } else {
      return 0;
    }
  };
  my @ret = $emit->($tree);
  ### @ret;
  pop @ret;
  return @ret;
}
{
  my $seq = Math::NumSeq::BalancedBinary->new;
  foreach (1 .. 100) {
    my ($i, $value) = $seq->next;
    my @bits = bit_split_hightolow($value);
    my $tree = depthfirst_bits_to_tree(@bits);
    ### $tree
    my @rev = depthfirst_tree_to_bits($tree);
    my $bits = join('',@bits);
    my $rev = join('',@rev);
    $bits eq $rev or die "oops $bits\nrev $rev";
  }
}

sub breadthfirst_bits_to_tree {
  my @bits = @_;
  ### breadthfirst_bits_to_tree(): join('',@bits)
  my $tree = 0;
  my @pending = (\$tree);
  while (@pending) {
    my $ref = shift @pending;
    if (shift @bits) {
      my @part = (0,0);
      $$ref = \@part;
      push @pending, \$part[0], \$part[1];
    } else {
      $$ref = 0;
    }
  }
  if (@pending) {
    die "Oops, more pending";
  }
  return $tree;
}
sub breadthfirst_tree_to_bits {
  my ($tree) = @_;
  ### breadthfirst_tree_to_bits(): $tree
  my @pending = ($tree);
  my @ret;
  while (@pending) {
    my $part = shift @pending;
    if ($part) {
      push @ret, 1;
      push @pending, $part->[0], $part->[1];
    } else {
      push @ret, 0;
    }
  };
  if (@pending) {
    die "Oops, more pending";
  }
  pop @ret;
  ### @ret
  return @ret;
}
{
  my $seq = Math::NumSeq::BalancedBinary->new;
  foreach (1 .. 100) {
    my ($i, $value) = $seq->next;
    my @bits = bit_split_hightolow($value);
    my $tree = breadthfirst_bits_to_tree(@bits);
    my @rev = breadthfirst_tree_to_bits($tree);
    my $bits = join('',@bits);
    my $rev = join('',@rev);
    $bits eq $rev or die "$bits\n$rev";
  }
}

sub bits_depth_to_breadth {
  my @bits = @_;
  return breadthfirst_tree_to_bits(depthfirst_bits_to_tree(@bits));
}
sub bits_breadth_to_depth {
  my @bits = @_;
  return depthfirst_tree_to_bits(breadthfirst_bits_to_tree(@bits));
}

#------------------------------------------------------------------------------
# A071162 - decimal of trees with at most one child per node,
#           so path left or right but not branching

# cf A209642 left-only trees, not in ascending order

MyOEIS::compare_values
  (anum => 'A071162',
   max_count => 1024,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got = (0);

     while (@got < $count) {
       my ($i, $value) = $seq->next;
       my @bits = bit_split_hightolow($value);
       my $tree = depthfirst_bits_to_tree(@bits);
       ### $value
       ### $tree
       if (bits_is_oneonly(@bits)) {
         push @got, $value;
       }
     }
     return \@got;
   });

sub bits_is_oneonly {
  my @bits = @_;
  ### bits_is_oneonly(): join('',@bits)
  push @bits, 0;
  my $good = 1;
  my $take;
  $take = sub {
    if (! @bits) {
      die "Oops, end of bits";
    }
    my $bit = shift @bits;
    ### $bit
    if ($bit) {
      my $left = &$take();
      my $right = &$take();
      ### $left
      ### $right
      if ($left == 1 && $right == 1) {
        $good = 0;
      }
      return 1;
    } else {
      return 0;
    }
  };
  &$take();
  if (@bits) {
    die "Oops, too many bits";
  }
  ### $good
  return $good;
}

#------------------------------------------------------------------------------
# A071152 - Lukasiewicz, binary with 0,2, including value=0

MyOEIS::compare_values
  (anum => 'A071152',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got = ('0');

     while (@got < $count) {
       my ($i, $value) = $seq->next;
       my $str = to_binary_str($value);
       $str =~ tr/1/2/;
       push @got, $str;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A072643 balanced binary width, including value=0

MyOEIS::compare_values
  (anum => 'A072643',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::DigitLength;
     my $dlen = Math::NumSeq::DigitLength->new (radix => 2);

     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got = (0);

     for (my $value = 0; @got < $count; $value++) {
       my ($i,$value) = $seq->next;
       push @got, $dlen->ith($value)/2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A071671 - permuted by A071651/A071652
#
# {
#   my $anum = 'A071671';
#   my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
#   my $diff;
#   if ($bvalues) {
#     my $seq = Math::NumSeq::BalancedBinary->new;
#     my @got;
#     for (my $value = 0; @got < @$bvalues; $value++) {
#       my $i = $seq->value_to_i($value);
#       push @got, $i || 0;
#     }
#     $diff = diff_nums(\@got, $bvalues);
#     if ($diff) {
#       MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
#       MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
#     }
#   }
#   skip (! $bvalues,
#         $diff, undef,
#         "$anum");
# }

#------------------------------------------------------------------------------
# A085223 - positions of single trailing zero

MyOEIS::compare_values
  (anum => 'A085223',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if (($value % 4) == 2) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A080237 = num trailing zeros

MyOEIS::compare_values
  (anum => 'A080237',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::DigitCountLow;
     my $low = Math::NumSeq::DigitCountLow->new (radix => 2, digit => 0);
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $low->ith($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A080116 predicate 0,1

MyOEIS::compare_values
  (anum => 'A080116',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got = (1);  # A080116 starts OFFSET=0 and reckons 0 as balanced
     for (my $value = 1; @got < $count; $value++) {
       push @got, ($seq->pred($value) ? 1 : 0);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A063171 - in binary

MyOEIS::compare_values
  (anum => 'A063171',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::BalancedBinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, to_binary_str($value);
     }
     return \@got;
   });

sub to_binary_str {
  my ($n) = @_;
  if (ref $n) {
    my $str = $n->as_bin;
    $str =~ s/^0b//;
    return $str;
  }
  if ($n == 0) { return '0'; }
  my @bits;
  while ($n) {
    push @bits, $n%2;
    $n = int($n/2);
  }
  return join('',reverse @bits);
}

#------------------------------------------------------------------------------
exit 0;
