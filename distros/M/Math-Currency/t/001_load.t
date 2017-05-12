# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Math::Currency' ); }

my $object = Math::Currency->new ();
isa_ok ($object, 'Math::Currency');


