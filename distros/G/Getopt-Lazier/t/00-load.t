#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Getopt::Lazier' ) || print "Bail out!\n";
}

diag( "Testing Getopt::Lazier $Getopt::Lazier::VERSION, Perl $], $^X" );
