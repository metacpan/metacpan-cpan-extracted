#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Device::RAID::Poller' ) || print "Bail out!\n";
}

diag( "Testing Device::RAID::Poller $Device::RAID::Poller::VERSION, Perl $], $^X" );
