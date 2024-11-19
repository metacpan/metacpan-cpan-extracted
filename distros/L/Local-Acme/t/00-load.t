#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Local::Acme' ) || print "Bail out!\n";
}

diag( "Testing Local::Acme $Local::Acme::VERSION, Perl $], $^X" );
