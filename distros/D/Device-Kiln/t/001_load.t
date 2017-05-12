# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Device::Kiln' ); }

my $object = Device::Kiln->new ({});
isa_ok ($object, 'Device::Kiln');


