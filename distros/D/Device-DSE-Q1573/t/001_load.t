# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Device::DSE::Q1573' ); }

my $object = Device::DSE::Q1573->new ();
isa_ok ($object, 'Device::DSE::Q1573');


