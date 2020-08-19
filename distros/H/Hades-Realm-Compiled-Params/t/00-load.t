#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hades::Realm::Compiled::Params' ) || print "Bail out!\n";
}

diag( "Testing Hades::Realm::Compiled::Params $Hades::Realm::Compiled::Params::VERSION, Perl $], $^X" );
