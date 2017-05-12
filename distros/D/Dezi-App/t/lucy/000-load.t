#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok('Dezi::Lucy');
    use_ok('Lucy');
}

diag(
    join( ' ',
        "Testing Dezi::Lucy $Dezi::Lucy::VERSION",
        "Lucy $Lucy::VERSION",
        ", Perl $], $^X" )
);
