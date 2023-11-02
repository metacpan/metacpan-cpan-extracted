# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 81;

my $class;

BEGIN {
    $class = 'Math::BigInt';
    use_ok($class);
}

while (<DATA>) {
    s/#.*$//;                   # remove comments
    s/\s+$//;                   # remove trailing whitespace
    next unless length;         # skip empty lines

    my @args = split /:/;
    my $want = pop @args;

    # binv() as an instance method

    {
        my ($x, $y);
        my $test = qq|\$x = $class -> new("$args[0]"); |
                 . qq|\$y = \$x -> binv();|;

        note "\n";
        note "$test\n";
        note "\n";

        eval "$test";

        is($@, "", "eval succeeded");
        is(ref($x), $class, "\$x is still a $class");
        is(ref($y), $class, "\$y is a $class");
        is($y, $want, "the output \$y has the right value");
        is($x, $want, "the invocand \$x has the right value");
    }

    # binv() as an class method

    {
        my ($y);
        my $test = qq|\$y = $class -> binv("$args[0]");|;

        note "\n";
        note "$test\n";
        note "\n";

        eval "$test";

        is($@, "", "eval succeeded");
        is(ref($y), $class, "\$y is a $class");
        is($y, $want, "the output \$y has the right value");
    }
}

__DATA__
-inf:0
-4:0
-2:0
-1:-1
0:inf
1:1
2:0
4:0
inf:0
NaN:NaN
