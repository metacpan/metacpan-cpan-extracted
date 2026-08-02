#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Fetch' )                   || print "Bail out!\n";
    use_ok( 'Fetch::Future' )           || print "Bail out!\n";
    use_ok( 'Fetch::Loop::Standalone' ) || print "Bail out!\n";
}

diag( "Testing Fetch $Fetch::VERSION, Perl $], $^X" );
