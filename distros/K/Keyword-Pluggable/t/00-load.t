#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Keyword::Pluggable' ) || print "Bail out!\n";
}

diag( "Testing Keyword::Pluggable $Keyword::Pluggable::VERSION, Perl $], $^X" );
