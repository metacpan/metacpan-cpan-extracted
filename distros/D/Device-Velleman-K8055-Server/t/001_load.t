# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Device::Velleman::K8055::Server' ); }

my $object = Device::Velleman::K8055::Server->new ();
isa_ok ($object, 'Device::Velleman::K8055::Server');


