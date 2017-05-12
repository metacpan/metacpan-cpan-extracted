#!/usr/bin/perl

## skip personal name fields in a translation

use strict;
use warnings;
use Test::More qw( no_plan );
use MARC::Record;
use MARC::Detrans;

## get a detransliteration engine 
my $config = MARC::Detrans::Config->new();
$config->detransFields( '100', '701' );
$config->languageCode( 'rus' );
my $engine = MARC::Detrans->newFromConfig( $config );

my $r = MARC::Record->new();
$r->append_fields( 
    MARC::Field->new( '008', ' ' x 35 . 'rus' ),
    MARC::Field->new( '041', ' ', ' ', 'h' => 'rus' ),
    MARC::Field->new( '100', ' ', ' ', a => 'test' ),
    MARC::Field->new( '701', ' ', ' ', a => 'test' )
);
$r = $engine->convert( $r );
my @errors = $engine->errors();
is( @errors, 2, 'got translation errors' );
is( $errors[0], 'field=100: skipped because of translation', 
    'correct error msg 1' );
is( $errors[1], 'field=701: skipped because of translation', 
    'correct error msg 2' );

