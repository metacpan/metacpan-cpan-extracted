# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 119;

my $class = "Math::BigRat";
use_ok($class);

note("btfac() as a class method");

while (<DATA>) {
    s/^\s+//;
    next if /^#/ || !/\S/;

    my ($x, $want) = split;

    # btfac() as an instance method

    {
        my $y;
        my $test = qq|\$y = $class -> new("$x") -> btfac();|;
        note("\n$test\n\n");
        eval $test;
        die $@ if $@;
        is($y, $want);
    }

    # btfac() as a class method

    {
        my $y;
        my $test = qq|\$y = $class -> btfac("$x");|;
        note("\n$test\n\n");
        eval $test;
        die $@ if $@;
        is($y, $want);
    }

    # btfac() as a function does not work, since objectify() converts the scalar
    # to a Math::BigInt, which is the name of the package in which objectify()
    # is defined.

#    {
#        my $y;
#        my $test = qq|\$y = $ {class}::btfac("$x");|;
#        note("\n$test\n\n");
#        eval $test;
#        die $@ if $@;
#        is($y, $want);
#    }

}

__DATA__

# Tests only for Math::BigRat

-3/2 NaN
-1/2 NaN
3/2 NaN
5/2 NaN

# Common tests for Math::BigInt, Math::BigFloat, and Math::BigRat:

-4 NaN
-3 NaN
-2 1
-1 1
0 1
1 1
2 2
3 3
4 4
5 10
6 18
7 28
8 80
9 162
10 280
11 880
12 1944
13 3640
14 12320
15 29160
16 58240
17 209440
18 524880
19 1106560
20 4188800
21 11022480
22 24344320
23 96342400
24 264539520
25 608608000
26 2504902400
27 7142567040
28 17041024000
29 72642169600
30 214277011200
31 528271744000
32 2324549427200
33 7071141369600
34 17961239296000
35 81359229952000
36 254561089305600
37 664565853952000
38 3091650738176000
39 9927882482918400
40 26582634158080000
41 126757680265216000
42 416971064282572800
43 1143053268797440000
44 5577337931669504000
45 18763697892715776000
46 52580450364682240000
47 262134882788466688000
48 900657498850357248000
49 2576442067869429760000
50 13106744139423334400000
