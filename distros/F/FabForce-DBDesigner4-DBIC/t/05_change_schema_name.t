#!perl -T

use strict;
use warnings;

use Test::More tests => 3;
use FindBin ();

BEGIN {
	use_ok( 'FabForce::DBDesigner4::DBIC' );
}

my $foo = FabForce::DBDesigner4::DBIC->new;
isa_ok( $foo, 'FabForce::DBDesigner4::DBIC', 'object is type F::D::D' );

$foo->schema_name( 'my_schema' );
is( $foo->_schema, 'my_schema' );
