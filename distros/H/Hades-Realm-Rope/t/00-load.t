#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hades::Realm::Rope' ) || print "Bail out!\n";
}

diag( "Testing Hades::Realm::Rope $Hades::Realm::Rope::VERSION, Perl $], $^X" );
