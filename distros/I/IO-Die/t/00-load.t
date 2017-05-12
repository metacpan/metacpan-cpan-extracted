#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'IO::Die' ) || print "Bail out!\n";
}

diag( "Testing IO::Die $IO::Die::VERSION, Perl $], $^X" );
