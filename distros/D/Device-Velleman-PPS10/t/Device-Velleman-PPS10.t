# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Device-Velleman-PPS10.t'

#########################

use Test::More tests => 2;

BEGIN { use_ok('Device::Velleman::PPS10') };

my $pps10 = Device::Velleman::PPS10->new;
isa_ok($pps10, 'Device::Velleman::PPS10');
