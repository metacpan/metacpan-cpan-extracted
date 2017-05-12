#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Device::PaloAlto::Firewall;

plan tests => 1;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test');

isa_ok( $fw->tester(), 'Device::PaloAlto::Firewall::Test' );
