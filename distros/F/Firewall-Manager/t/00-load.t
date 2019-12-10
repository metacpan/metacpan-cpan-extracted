#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Firewall::Manager' ) || print "Bail out!\n";
}

diag( "Testing Firewall::Manager $Firewall::Manager::VERSION, Perl $], $^X" );
