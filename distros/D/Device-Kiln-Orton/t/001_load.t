# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Device::Kiln::Orton' ); }

my $object = Device::Kiln::Orton->new ();
isa_ok ($object, 'Device::Kiln::Orton');


