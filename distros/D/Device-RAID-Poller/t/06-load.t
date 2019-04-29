#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Device::RAID::Poller::Backends::Adaptec_arcconf' ) || print "Bail out!\n";
}

#diag( "Testing Device::RAID::Poller::Backends::Adaptec_arcconf $Device::RAID::Poller::Backends::Adaptec_arcconf::VERSION, Perl $], $^X" );
