#!perl -T

use strict;
use warnings;

use Test::More tests=>9;

## methods should croak when called wrong so that MARC::Record users can 
## identify the location of their mistakes.

BEGIN {
    use_ok( "MARC::Record" );
    use_ok( "MARC::Field" );
}

my $record = MARC::Record->new();
isa_ok( $record, "MARC::Record" );

my $f100 = MARC::Field->new( '100', '', '', 'a' => 'author' );
isa_ok( $f100, "MARC::Field", "F100 ok" );

my $f200 = MARC::Field->new( '245', '', '', 'b' => 'title' );
isa_ok( $f200, "MARC::Field", "F200 ok" );

INSERT_FIELDS_AFTER: {
    eval {
	    my $n = $record->insert_fields_after( $f100, 'blah' );
    };

    like( $@, qr/All arguments must be MARC::Field objects/, 
	'insert_fields_after() croaks appropriately' ); 

}


INSERT_FIELDS_BEFORE: {
    eval { 
	$record->insert_fields_before( $f100, 'blah' );
    };

    like( $@, qr/All arguments must be MARC::Field objects/,
	'insert_fields_before() croaks appropriately' );
}


INSERT_GROUPED_FIELD: {
    eval {
	    my $n = $record->insert_grouped_field( 'blah' );
    };

    like( $@, qr/Argument must be MARC::Field object/,
	'insert_grouped_field() croaks appropriately' );
}


APPEND_FIELDS: {
    eval {
	$record->append_fields( 'blah' );
    };

    like( $@, qr/Arguments must be MARC::Field objects/,
	'append_fields() croaks appropriately' );
}
