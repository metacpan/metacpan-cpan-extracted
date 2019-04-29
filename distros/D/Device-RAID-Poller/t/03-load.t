#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Device::RAID::Poller::Backends::Linux_mdadm' ) || print "Bail out!\n";
}

#diag( "Testing Device::RAID::Poller::Backends::Linux_mdadm $Device::RAID::Poller::Backends::Linux_mdadm::VERSION, Perl $], $^X" );
