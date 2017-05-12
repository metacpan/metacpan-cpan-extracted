#!/usr/bin/perl

## make sure all repeated fields are processed when 
## one of them have problems. 

use strict;
use warnings;
use Test::More qw( no_plan );
use MARC::Record;

use_ok( 'MARC::Detrans' );
use_ok( 'MARC::Detrans::Rules' );
use_ok( 'MARC::Detrans::Rule' );
use_ok( 'MARC::Detrans::Config' );

my $engine = MARC::Detrans->new( config => 't/testconfig.xml' );

OK: {
    my $r = MARC::Record->new();
    $r->append_fields( 
        MARC::Field->new( '008', ' ' x 35 . 'rus' ),
        MARC::Field->new( '440', ' ', ' ', a => 'a' ),
        MARC::Field->new( '440', ' ', ' ', a => 'b' )
    );
    $r = $engine->convert( $r );
    is( $engine->errors(), 0, 'errors()' );
    is( $r->fields(), 6, 'expected amt of fields' );
}

NOT_OK: {
    my $r = MARC::Record->new();
    $r->append_fields( 
        MARC::Field->new( '008', ' ' x 35 . 'rus' ),
        MARC::Field->new( '440', ' ', ' ', a => 'j' ),
        MARC::Field->new( '440', ' ', ' ', a => 'a' )
    );
    $r = $engine->convert( $r );
    is( $engine->errors(), 1, 'errors()' );
    is( $r->fields(), 5, 'expected amount of fields' );
}

