#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Debug::Easy') || print "Bail out! Can't load Debug::Easy!\n";
}

# diag( "Testing Debug::Easy $Debug::Easy::VERSION, Perl $], $^X" );
