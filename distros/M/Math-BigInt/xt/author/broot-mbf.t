# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

use Math::BigFloat;

my $class = 'Math::BigFloat';

# Verify that accuracy and precision is restored (CPAN RT #150523).

{
    $class -> accuracy(10);
    is($class -> accuracy(), 10, "class accuracy is 10 before broot()");
    my $x = $class -> new(12345);
    $x -> broot(2);
    is($class -> accuracy(), 10, "class accuracy is 10 after broot()");
}

{
    $class -> precision(-10);
    is($class -> precision(), -10, "class precision is -10 before broot()");
    my $x = $class -> new(12345);
    $x -> broot(2);
    is($class -> precision(), -10, "class precision is -10 after broot()");
}

done_testing();
