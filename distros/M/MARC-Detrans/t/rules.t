#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw( no_plan );

use_ok( 'MARC::Detrans::Rules' );
use_ok( 'MARC::Detrans::Rule' );

my $rules = MARC::Detrans::Rules->new();
isa_ok( $rules, 'MARC::Detrans::Rules' );

$rules->addRule( MARC::Detrans::Rule->new( from=>'a', to=>'A', escape=>'g' ) );
$rules->addRule( MARC::Detrans::Rule->new( from=>'b', to=>'B', escape=>'h' ) );
$rules->addRule( MARC::Detrans::Rule->new( from=>'ac', to=>'Z', escape=>'i' ) );
$rules->addRule( MARC::Detrans::Rule->new( from=>'|*+', to=>'X', escape=>'j' ) );

my $esc = chr(0x1B);
my $ascii = chr(0x1B).chr(0x28).chr(0x42);

is( $rules->convert('a'), "${esc}gA${ascii}", 'convert() 1' );
is( $rules->convert('ab'), "${esc}gA${esc}hB${ascii}", 'convert() 2' );
is( $rules->convert('aab'), "${esc}gAA${esc}hB${ascii}", 'convert() 3' );
is( $rules->convert('aac'), "${esc}gA${esc}iZ${ascii}", 'convert() 4' );
is( $rules->convert('|*+'), "${esc}jX${ascii}", "convert() 5" );

## non-existant mapping
ok( ! $rules->convert('acw'), 'non-existant mapping' );
is( $rules->error(), 'no matching rule found for "w" [0x77] at position 3',
    'non-existant mapping error message' );
ok( ! $rules->error(), 'error message erased on retrieval' );

$rules->addRule( MARC::Detrans::Rule->new( from => 'z', to => '^ESCz' ) );
is( $rules->convert('z'), chr(0x1B).'z', 'rule with ^ESC' );


