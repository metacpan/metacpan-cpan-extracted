#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN {
    use_ok( 'Digest::SipHash' ) || print "Bail out!\n";
}

diag( "Testing Digest::SipHash $Digest::SipHash::VERSION, Perl $], $^X" );
