use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

plan tests => 1;

use lib qw[lib ../lib];

BEGIN {
    use_ok( 'HATX' ) || print "Bail out!\n";
}

diag( "Testing HATX $HATX::VERSION, Perl $], $^X" );


done_testing;
