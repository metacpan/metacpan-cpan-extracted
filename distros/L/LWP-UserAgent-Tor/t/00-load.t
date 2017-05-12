#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'LWP::UserAgent::Tor' ) || print "Bail out!\n";
}

diag( "Testing LWP::UserAgent::Tor $LWP::UserAgent::Tor::VERSION, Perl $], $^X" );
