#!perl -Tw

use strict;
use integer;

use Test::More tests => 9; 

BEGIN {
    use_ok( 'MARC::Record' );
}

my $r = MARC::Record->new();

$r->insert_fields_ordered( 
    MARC::Field->new( '100', '', '', a => 'foo' )
);

my @fields = $r->fields();
isa_ok( $fields[0], 'MARC::Field' );
is( $fields[0]->tag(), '100', 'insert_fields_ordered works with empty rec' );

$r->insert_fields_ordered(
    MARC::Field->new( '110', '', '', a => 'bar' ),
    MARC::Field->new( '105', '', '', b => 'bez' ),
    MARC::Field->new( '008', '', '', c => 'fez' )
);

@fields = $r->fields();
my @tags = ();
foreach (@fields ) { 
    isa_ok( $_, 'MARC::Field' ); 
    push( @tags, $_->tag() ); 
}

is( scalar(@fields), 4, 'insert_fields_ordered added multiple fields' );
is_deeply( \@tags, [ '008', '100', '105', '110' ], 
    'insert_fields_ordered() added fields in numeric order' );


