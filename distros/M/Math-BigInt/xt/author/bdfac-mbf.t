# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 123;

my $class = "Math::BigFloat";
use_ok($class);

note("bdfac() as a class method");

while (<DATA>) {
    s/^\s+//;
    next if /^#/ || !/\S/;

    my ($x, $want) = split;

    # bdfac() as an instance method

    {
        my $y;
        my $test = qq|\$y = $class -> new("$x") -> bdfac();|;
        note("\n$test\n\n");
        eval $test;
        die $@ if $@;
        is($y, $want);
    }

    # bdfac() as a class method

    {
        my $y;
        my $test = qq|\$y = $class -> bdfac("$x");|;
        note("\n$test\n\n");
        eval $test;
        die $@ if $@;
        is($y, $want);
    }

    # bdfac() as a function does not work, since objectify() converts the scalar
    # to a Math::BigInt, which is the name of the package in which objectify()
    # is defined.

#    {
#        my $y;
#        my $test = qq|\$y = $ {class}::bdfac("$x");|;
#        note("\n$test\n\n");
#        eval $test;
#        die $@ if $@;
#        is($y, $want);
#    }

}

__DATA__

# Tests only for Math::BigFloat

-1.5 NaN
-0.5 NaN
1.5 NaN
2.5 NaN

# Common tests for Math::BigInt, Math::BigFloat, and Math::BigRat:

NaN NaN
-inf NaN
-3 NaN
-2 NaN
-1 1
0 1
1 1
2 2
3 3
4 8
5 15
6 48
7 105
8 384
9 945
10 3840
11 10395
12 46080
13 135135
14 645120
15 2027025
16 10321920
17 34459425
18 185794560
19 654729075
20 3715891200
21 13749310575
22 81749606400
23 316234143225
24 1961990553600
25 7905853580625
26 51011754393600
27 213458046676875
28 1428329123020800
29 6190283353629375
30 42849873690624000
31 191898783962510625
32 1371195958099968000
33 6332659870762850625
34 46620662575398912000
35 221643095476699771875
36 1678343852714360832000
37 8200794532637891559375
38 63777066403145711616000
39 319830986772877770815625
40 2551082656125828464640000
41 13113070457687988603440625
42 107145471557284795514880000
43 563862029680583509947946875
44 4714400748520531002654720000
45 25373791335626257947657609375
46 216862434431944426122117120000
47 1192568192774434123539907640625
48 10409396852733332453861621760000
49 58435841445947272053455474390625
50 520469842636666622693081088000000
inf inf
