use strict;
use warnings;
use 5.010;

use Test::More tests => 1;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::InterfaceStats;

use lib 't/lib';
use Local::TestSupport qw(pseudo_api_call);


my $log = pseudo_api_call(
    "./t/xml/op/logging_status/01_log_collector.xml", 
    sub { Device::Firewall::PaloAlto::Op::InterfaceStats->_new(@_) }
);

isa_ok( $log, 'Device::Firewall::PaloAlto::Op::InterfaceStats' );

