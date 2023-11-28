#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::Actions::sagan_rules' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::Actions::sagan_rules::VERSION, Perl $], $^X" );
