#!/usr/bin/perl
#
use strict;
use warnings;
use Test::More qw( no_plan );
use MARC::Record;
use MARC::Detrans;

## make sure cyril will correctly not detransliterate records
## where the target script is already present

my $engine = MARC::Detrans->new( config => 't/testconfig.xml' );

my $r = MARC::Record->new();
$r->append_fields( 
    MARC::Field->new( '008', ' ' x 35 . 'rus' ),
    MARC::Field->new( '066', 0, 0, 'a', '(N' ),
    MARC::Field->new( '246', 0, 1, a => 'foo' )
);

$r = $engine->convert( $r );
ok( ! $r, 'convert() returned undef' );

my @errors = $engine->errors();
is( @errors, 1, 'got error when 246 indicator 2 is 1' );
is( $errors[0], 'target script already present', 'expected error' );
