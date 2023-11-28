#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::DefaultConfig' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::DefaultConfig::VERSION, Perl $], $^X" );
