use Test::More tests => 1;
use strict;
use warnings FATAL => 'all';

BEGIN {
    use_ok('Interchange6::Currency') || print "Bail out!\n";
}

diag "Testing Interchange6::Currency $Interchange6::Currency::VERSION, Perl $], $^X";
