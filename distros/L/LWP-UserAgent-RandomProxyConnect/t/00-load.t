#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'LWP::UserAgent::RandomProxyConnect' ) || print "Bail out!\n";
}

diag( "Testing LWP::UserAgent::RandomProxyConnect $LWP::UserAgent::RandomProxyConnect::VERSION, Perl $], $^X" );
