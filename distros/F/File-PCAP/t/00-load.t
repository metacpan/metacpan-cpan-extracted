#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'File::PCAP' ) || print "Bail out!\n";
}

diag( "Testing File::PCAP $File::PCAP::VERSION, Perl $], $^X" );
