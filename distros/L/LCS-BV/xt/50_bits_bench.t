#!perl
use 5.006;
use open qw(:locale);
use strict;
use warnings;
#use utf8;

use lib qw(../lib/);

use Benchmark qw(:all) ;
use Data::Dumper;
use Test::More;

use integer;
no warnings 'portable'; # for 0xffffffffffffffff

my $tests = [
  ['bits_0',0,0],
  ['prefix_8',0xff00000000000000,8],
  ['suffix_8',0x00000000000000ff,8],
  ['prefix_16',0xffff000000000000,16],
  ['prefix_64',0xffffffffffffffff,64],
];

if (1) {
  for my $test (@{$tests}) {
    is(kernighan($test->[1]),$test->[2],'kernighan '.$test->[0]);
    is(parallel1($test->[1]),$test->[2],'parallel1 '.$test->[0]);
    #is(parallel2($test->[1]),$test->[2],'parallel2 '.$test->[0]);
    is(parallel3($test->[1]),$test->[2],'parallel3 '.$test->[0]);
    is(best(     $test->[1]),$test->[2],'best '.$test->[0]);
    #is(lookup(   $test->[1]),$test->[2],'lookup '.$test->[0]);
  }
  done_testing;
}


sub kernighan {
  my $v = shift;

  my $c; # count
  # 5 operations per iteration (=bits on)
  for ($c = 0; $v; $c++) {
    $v &= $v - 1; # clear the least significant bit set
  }
  return $c;
}

sub parallel1 {
  my $v = shift;

  # catch overflow
  my $c = ($v & 0x8000000000000000) ? 1 : 0;
  $v = $v & 0x7fffffffffffffff;
  # 24 + 5 operations
  $v = ($v & 0x5555555555555555) + (($v & 0xaaaaaaaaaaaaaaaa) >> 1);
  $v = ($v & 0x3333333333333333) + (($v & 0xcccccccccccccccc) >> 2);
  $v = ($v & 0x0f0f0f0f0f0f0f0f) + (($v & 0xf0f0f0f0f0f0f0f0) >> 4);
  $v = ($v & 0x00ff00ff00ff00ff) + (($v & 0xff00ff00ff00ff00) >> 8);
  $v = ($v & 0x0000ffff0000ffff) + (($v & 0xffff0000ffff0000) >>16);
  $v = ($v & 0x00000000ffffffff) + (($v & 0xffffffff00000000) >>32);

  #print '$v: ',$v,' $c: ',$c,"\n";
  return $v + $c;
}

sub parallel3 {
  my $v = shift;

  # catch overflow
  my $c = ($v & 0x8000000000000000) ? 1 : 0;
  $v = $v & 0x7fffffffffffffff;
  # 24 + 5 operations
  $v = ($v & 0x5555555555555555) + (($v >> 1) & 0x5555555555555555);
  $v = ($v & 0x3333333333333333) + (($v >> 2) & 0x3333333333333333);
  $v = ($v & 0x0f0f0f0f0f0f0f0f) + (($v >> 4) & 0x0f0f0f0f0f0f0f0f);
  $v = ($v & 0x00ff00ff00ff00ff) + (($v >> 8) & 0x00ff00ff00ff00ff);
  $v = ($v & 0x0000ffff0000ffff) + (($v >>16) & 0x0000ffff0000ffff);
  $v = ($v & 0x00000000ffffffff) + (($v >>32) & 0x00000000ffffffff);

  return $v + $c;
}

# does not work
sub parallel2 {
  my $v = shift;

  # catch overflow
  #my $c = ($v & 0x8000000000000000) ? 1 : 0;
  #$v = $v & 0x7fffffffffffffff;
  # 20 + 5 operations
  $v = $v - (($v >> 1) & 0x5555555555555555);
  $v = (($v >> 2) & 0x3333333333333333 >> 2) + ($v & 0x3333333333333333);
  #$v = (($v >> 2) & 0x3333333333333333 >> 2);
  $v = (($v >> 4) + $v) & 0xf0f0f0f0f0f0f0f0;
  $v = (($v >> 8) + $v) & 0x00ff00ff00ff00ff;
  $v = (($v >> 16) + $v) & 0x0000ffff0000ffff;
  $v = (($v >> 32) + $v) & 0x00000000ffffffff;

  #print '$v: ',$v,' $c: ',$c,"\n";
  #return $v + $c;
  #return $v;
  return $v & 0x000000000000003f;
}

my @bits =  (
  0x5555555555555555,
  0x3333333333333333,
  0x0f0f0f0f0f0f0f0f,
  0x00ff00ff00ff00ff,
  0x0000ffff0000ffff,
  0x00000000ffffffff,
);
my @s    =  (1, 2, 4, 8, 16, 32);
sub lookup {
  my $v = shift;

  my $i;
  for ($i = 0; $i < 6; $i++) {
     $v = (($v >> $s[$i]) & $bits[$i]) + ($v & $bits[$i]);
  }
  return $v;
}

sub best {
  my $v = shift;

  # 12 operations
  $v = $v - (($v >> 1) & 0x5555555555555555);
  $v = ($v & 0x3333333333333333) + (($v >> 2) & 0x3333333333333333);
  # (bytesof($v) -1) * bitsofbyte = (8-1)*8 = 56 ----------------------vv
  $v = (($v + ($v >> 4) & 0x0f0f0f0f0f0f0f0f) * 0x0101010101010101) >> 56;

  return $v;
}


if (1) {
  for my $test (@{$tests}) {
    print "\n",$test->[0],"\n";
    my $bits = $test->[1];
    cmpthese( -1, {
       'kernighan' => sub {
            kernighan($bits)
        },
       'parallel1' => sub {
            parallel1($bits)
        },
        #'parallel2' => sub {
        #    parallel2($bits)
        #},
        'parallel3' => sub {
            parallel3($bits)
        },
        'best' => sub {
            best($bits)
        },
        #'lookup' => sub {
        #    lookup($bits)
        #},
    });
  }
}

=pod

https://groups.google.com/forum/?hl=en#!msg/comp.graphics.algorithms/ZKSegl2sr4c/QYTwoPSx30MJ
Fast bitcount:

        #define BX_(x)                ((x) - (((x)>>1)&0x77777777)                \
                             - (((x)>>2)&0x33333333)                \
                             - (((x)>>3)&0x11111111))

        #define BITCOUNT(x)        (((BX_(x)+(BX_(x)>>4)) & 0x0F0F0F0F) % 255)


int bitcount (long x)
    {static long b[] = {0x55555555, 0x33333333, 0x0f0f0f0f, 0x00ff00ff, 0x0000ffff};
     static int s[] = {1, 2, 4, 8, 16};
     int i;
     for (i = 0; i < 5; i++)
        x = ((x >> s[i]) & b[i]) + (x & b[i]);
     return ((int) x);
    }

int Bits(int w)
{
  int n;
  for (n=0; w!=0; n++)
    w&=w-1;
  return n;
}

https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel

The best method for counting bits in a 32-bit integer v is the following:

v = v - ((v >> 1) & 0x55555555);                    // reuse input as temporary
v = (v & 0x33333333) + ((v >> 2) & 0x33333333);     // temp
c = ((v + (v >> 4) & 0xF0F0F0F) * 0x1010101) >> 24; // count

The best bit counting method takes only 12 operations, which is the same as the lookup-table method,
but avoids the memory and potential cache misses of a table.
It is a hybrid between the purely parallel method above and the earlier methods
using multiplies (in the section on counting bits with 64-bit instructions),
though it doesn't use 64-bit instructions.
The counts of bits set in the bytes is done in parallel,
and the sum total of the bits set in the bytes is computed
by multiplying by 0x1010101 and shifting right 24 bits.

A generalization of the best bit counting method to integers of bit-widths upto 128 (parameterized by type T) is this:

v = v - ((v >> 1) & (T)~(T)0/3);                           // temp
v = (v & (T)~(T)0/15*3) + ((v >> 2) & (T)~(T)0/15*3);      // temp
v = (v + (v >> 4)) & (T)~(T)0/255*15;                      // temp
c = (T)(v * ((T)~(T)0/255)) >> (sizeof(T) - 1) * CHAR_BIT; // count

