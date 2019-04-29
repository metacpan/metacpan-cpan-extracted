#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Device::RAID::Poller::Backends::FBSD_graid3' ) || print "Bail out!\n";
}

#diag( "Testing Device::RAID::Poller::Backends::FBSD_graid3 $Device::RAID::Poller::Backends::FBSD_graid3::VERSION, Perl $], $^X" );
