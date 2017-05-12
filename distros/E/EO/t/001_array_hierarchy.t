# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More no_plan => 1;

BEGIN { use_ok( 'EO::Hierarchy' ); }
BEGIN { use_ok( 'EO::Array' ); }

use constant FOO => 0;
use constant BAZ => 1;

ok( my $object = EO::Hierarchy->new());
ok( $object->delegate( EO::Array->new() ) );
ok( $object->at(FOO, 'bar') );
ok( $object->add_child(BAZ) );
is( $object->at(BAZ)->at(FOO), 'bar' );
