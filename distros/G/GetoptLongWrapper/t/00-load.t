#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use lib 'lib';

plan tests => 1;

BEGIN {
    use_ok( 'GetoptLongWrapper' ) || print "Bail out!\n";
}

diag( "Testing GetoptLongWrapper $GetoptLongWrapper::VERSION, Perl $], $^X" );
