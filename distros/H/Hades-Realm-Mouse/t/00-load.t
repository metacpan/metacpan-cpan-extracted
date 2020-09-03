#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hades::Realm::Mouse' ) || print "Bail out!\n";
}

diag( "Testing Hades::Realm::Mouse $Hades::Realm::Mouse::VERSION, Perl $], $^X" );
