#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Device::RAID::Poller::Backends::Avago_tw_cli' ) || print "Bail out!\n";
}

#diag( "Testing Device::RAID::Poller::Backends::Avago_tw_cli $Device::RAID::Poller::Backends::Avago_tw_cli::VERSION, Perl $], $^X" );
