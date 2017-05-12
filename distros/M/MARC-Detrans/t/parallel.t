#!/usr/bin/perl

## parallel title skipping

use strict;
use warnings;
use Test::More qw( no_plan );
use MARC::Record;
use MARC::Detrans;

## get a detransliteration engine that attempts to convert 246 fields
my $config = MARC::Detrans::Config->new();
$config->detransFields( '246' );
$config->languageCode( 'rus' );
my $engine = MARC::Detrans->newFromConfig( $config );

INDICATOR_2_IS_1: {
    my $r = MARC::Record->new();
    $r->append_fields( 
        MARC::Field->new( '008', ' ' x 35 . 'rus' ),
        MARC::Field->new( '246', 0, 1, a => 'foo' )
    );
    $r = $engine->convert( $r );
    my @errors = $engine->errors();
    is( @errors, 1, 'got error when 246 indicator 2 is 1' );
    is( $errors[0], 'field=246: skipped parallel title', 'correct error msg' );
}

INDICATOR_2_IS_5: {
    my $r = MARC::Record->new();
    $r->append_fields( 
        MARC::Field->new( '008', ' ' x 35 . 'rus' ),
        MARC::Field->new( '246', 0, 5, a => 'foo' )
    );
    $r = $engine->convert( $r );
    my @errors = $engine->errors();
    is( @errors, 1, 'got error when 246 indicator 2 is 5' );
    is( $errors[0], 'field=246: skipped parallel title', 'correct error msg' );
}

FIRST_SUBFIELD_IS_I: {
    my $r = MARC::Record->new();
    $r->append_fields( 
        MARC::Field->new( '008', ' ' x 35 . 'rus' ),
        MARC::Field->new( '246', 0, ' ', i => 'foo' )
    );
    $r = $engine->convert( $r );
    my @errors = $engine->errors();
    is( @errors, 1, 'got error when 246 starts with subfield i' );
    is( $errors[0], 'field=246: skipped parallel title', 'correct error msg' );
}



