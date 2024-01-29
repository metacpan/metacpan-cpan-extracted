# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

use Math::BigFloat;

my $class = 'Math::BigFloat';

# Verify that accuracy and precision is restored (CPAN RT #150523).

{
    $class -> accuracy(10);
    is($class -> accuracy(), 10, "class accuracy is 10 before bcos()");
    my $x = $class -> new("1.2345");
    $x -> bcos();
    is($class -> accuracy(), 10, "class accuracy is 10 after bcos()");
}

{
    $class -> precision(-10);
    is($class -> precision(), -10, "class precision is -10 before bcos()");
    my $x = $class -> new("1.2345");
    $x -> bcos();
    is($class -> precision(), -10, "class precision is -10 after bcos()");
}

done_testing();
