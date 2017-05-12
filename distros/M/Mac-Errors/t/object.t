use strict;

use Test::More tests => 7;

use Mac::Errors qw( %MacErrors );

my $object = $MacErrors{ 'openErr' };
isa_ok( $object, 'Mac::Errors' );
can_ok( $object, 'symbol' );
can_ok( $object, 'number' );
can_ok( $object, 'description' );
is( $object->symbol,      'openErr' );
is( $object->number,      -23 );
is( $object->description, 'I/O System Errors' );
