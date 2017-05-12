#!perl -Tw

use Test::More tests => 6; 

use strict;

## make sure that MARC::Field::subfield() is aware of the context 
## in which it is called. In list context it returns *all* subfields
## and in scalar just the first.

use_ok( 'MARC::Field' );
my $field = MARC::Field->new( '245', '', '', a=>'foo', b=>'bar', a=>'baz' );
isa_ok( $field, 'MARC::Field' );

my $subfieldA = $field->subfield( 'a' );
is( $subfieldA, 'foo', 'subfield() in scalar context' );

my @subfieldsA = $field->subfield( 'a' );
is( $subfieldsA[0], 'foo', 'subfield() in list context 1' );
is( $subfieldsA[1], 'baz', 'subfield() in list context 2' );

## should not be able to call subfield on field < 010
$field = MARC::Field->new( '000', 'foobar' );
eval { $field->subfield( 'a' ) };
like( 
    $@, qr/just tags below 010/, 
    'subfield cannot be called on fields < 010' 
);

