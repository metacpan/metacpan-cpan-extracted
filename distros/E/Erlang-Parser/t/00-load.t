#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Erlang::Parser' ) || print "Bail out!\n";
}

diag( "Testing Erlang::Parser $Erlang::Parser::VERSION, Perl $], $^X" );
