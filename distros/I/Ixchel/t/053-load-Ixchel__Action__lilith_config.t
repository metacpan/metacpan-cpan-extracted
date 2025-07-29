#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::Actions::lilith_config' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::Actions::lilith_config::VERSION, Perl $], $^X" );
