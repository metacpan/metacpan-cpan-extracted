#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 79;

use Math::Primality qw/prime_count/;
use Math::GMPz;

my $i = 0;
my $primes;
while (<DATA>) {
  chomp;
  $primes = prime_count($i);
  ok ( $primes == $_, "$primes ?= $_ = prime_count($i)");
  $i++;
}

__DATA__
0
0
1
2
2
3
3
4
4
4
4
5
5
6
6
6
6
7
7
8
8
8
8
9
9
9
9
9
9
10
10
11
11
11
11
11
11
12
12
12
12
13
13
14
14
14
14
15
15
15
15
15
15
16
16
16
16
16
16
17
17
18
18
18
18
18
18
19
19
19
19
20
20
21
21
21
21
21
21
