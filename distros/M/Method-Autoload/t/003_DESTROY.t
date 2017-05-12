# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 4;

BEGIN { use_ok( 'Method::Autoload' ); }

my $object = Method::Autoload->new ();
isa_ok ($object, 'Method::Autoload');
is($object->DESTROY, "0E0", 'DESTORY');
ok($object->DESTROY, 'DESTORY');
