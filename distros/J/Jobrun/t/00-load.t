#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Jobrun' ) || print "Bail out!\n";
}

diag( "Testing Jobrun $Jobrun::VERSION, Perl $], $^X" );
