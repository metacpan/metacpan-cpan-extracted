#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';

plan tests => 1;

BEGIN {
    use_ok( 'EveOnline::Api' ) || print "Bail out!\n";
}

diag( "Testing EveOnline::Api $EveOnline::Api::VERSION, Perl $], $^X" );
