#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'FSM::Basic' ) || print "Bail out!\n";
}

diag( "Testing FSM::Basic $FSM::Basic::VERSION, Perl $], $^X" );
