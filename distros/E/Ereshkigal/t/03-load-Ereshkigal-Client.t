#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ereshkigal::Client' ) || print "Bail out!\n";
}

diag( "Testing Ereshkigal::Client $Ereshkigal::Client::VERSION, Perl $], $^X" );
