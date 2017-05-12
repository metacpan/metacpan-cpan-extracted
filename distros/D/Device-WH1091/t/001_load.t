# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Device::WH1091' ); }

my $object = Device::WH1091->new ();
isa_ok ($object, 'Device::WH1091');


