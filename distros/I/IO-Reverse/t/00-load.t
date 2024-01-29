#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'IO::Reverse' ) || print "Bail out!\n";
}

diag( "Testing IO::Reverse $IO::Reverse::VERSION, Perl $], $^X" );
