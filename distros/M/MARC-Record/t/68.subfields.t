#!perl -Tw

use Test::More tests => 4; 

use strict;

## make sure that MARC::Field::subfield() is aware of the context 
## in which it is called. In list context it returns *all* subfields
## and in scalar just the first.

use_ok( 'MARC::Field' );
my $field = MARC::Field->new( '245', '', '', a=>'foo', b=>'bar', a=>'baz' );
isa_ok( $field, 'MARC::Field' );

my @subfields = $field->subfields();
is_deeply(\@subfields, [ ['a' => 'foo'], ['b' => 'bar'], ['a' => 'baz'] ], 'subfields() returns same subfields');

$field = MARC::Field->new( '000', 'foobar' );
@subfields = $field->subfields();
ok(!@subfields, 'subfields() on a controlfield returns empty array');
