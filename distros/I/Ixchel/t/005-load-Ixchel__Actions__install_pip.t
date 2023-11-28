#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::Actions::install_pip' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::Actions::install_pip::VERSION, Perl $], $^X" );
