#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw( no_plan );

use_ok( 'MARC::Field' );
use_ok( 'MARC::Detrans::Config' );
my $config = MARC::Detrans::Config->new( 't/testconfig.xml' );
isa_ok( $config, 'MARC::Detrans::Config' );

## test the char rules
my $rules = $config->rules();
isa_ok( $rules, 'MARC::Detrans::Rules' );
is( $rules->convert('bkh'), chr(0x1B) . '(N' . 'BH' . chr(0x1B) . chr(0x28) . 
    chr(0x42) , 'rules convert()' );

## test a rule with a position attribute
is( $rules->convert('MM'), chr(0x1B) . '(N' . 'xm' . chr(0x1B) . chr(0x28) . 
    chr(0x42), 'rules convert with position' );

## test the 1 name rule
my $names = $config->names();
isa_ok( $names, 'MARC::Detrans::Names' );

my $field = MARC::Field->new( 100, '', '', 
    a   => 'Nicholas ',
    b   => 'I, ',
    c   => 'Emperor of Russia, ',
    d   => '1796-1855'
);
my $esc = chr(0x1B);
is_deeply( 
    $names->convert( $field ),
    [
        a   => "$esc(NnIKOLAJ${esc}s, ",
        b   => 'I, ',
        c   => "$esc(NiMPERATOR${esc}s $esc(NwSEROSSIJSKIJ${esc}s, ",
        d   => '1796-1855'
    ],
    'names convert()'
);

## make sure language stuff can be extracted
is( $config->languageName(), 'Russian', 'languageName()' );
is( $config->languageCode(), 'rus', 'languageCode()' );

## check out the fields we were asked to detransliterate
is_deeply( [$config->detransFields()], [ 100, 440 ], 'detransFields()' );
ok( $config->needsDetrans( field=>'440', subfield=>'a' ), 'needsDetrans()' );
ok( $config->needsCopy( field=>'100', subfield=>'d' ), 'needsCopy()' );
ok( ! $config->needsDetrans( field=>'245', subfield=>'d' ), 
    'does not needsDetrans()' ); 
ok( ! $config->needsCopy( field=>'245', subfield=>'d' ), 
    'does not needsCopy()' ); 

is_deeply( [ $config->allEscapeCodes() ], [ '(N', '(Q' ], 'allEscapeCodes()' );
