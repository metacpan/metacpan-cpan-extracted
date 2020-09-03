#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hades::Realm::Moose' ) || print "Bail out!\n";
}

diag( "Testing Hades::Realm::Moose $Hades::Realm::Moose::VERSION, Perl $], $^X" );
