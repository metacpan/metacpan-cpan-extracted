#!/usr/bin/env perl
# Device::OUI Copyright 2008 Jason Kohles
use strict; use warnings;
use FindBin qw( $Bin );
use IO::File;
BEGIN { require "$Bin/device-oui-test-lib.pl" }

plan tests => 4263;

Device::OUI->import(qw( normalize_oui oui_cmp parse_oui_entry ));

my @ordered = map { sprintf( "%02X-%02X-%02X", $_, $_, $_ ) } 0 .. 255;
my @ouis = (
    ( map { $_->{ 'oui' } } samples() ), @ordered,
    qw( 00-00-01 00-00-02 ),
);
my @bytes = map { sprintf( "%02X", $_ ) } ( 0 .. 255, reverse 0 .. 255 );
while ( @bytes > 3 ) {
    push( @ouis, join( '-', splice( @bytes, 0, 3 ) ) );
}

my @shuffled = ();
{
    my @tmp = @ouis;
    while ( @tmp ) {
        push( @shuffled, splice( @tmp, rand( @tmp ), 1 ) );
    }
}

for my $oui ( @ouis ) {
    for my $test ( mutate_oui( $oui ) ) {
        # two-for-one sale, we get to test normalize_oui and oui_cmp at the
        # same time!
        is(
            $oui,
            normalize_oui( $test ),
            "normalize_oui( '$test' ) == $oui",
        );
    }
}

my $ref = shift( @ordered );
while ( @ordered ) {
    my $test = shift( @ordered );
    is( oui_cmp( $ref, $test ), -1, "oui_cmp( $ref < $test )" );
    is( oui_cmp( $test, $ref ), +1, "oui_cmp( $ref > $test )" );
}

{
    my $fh = IO::File->new( "$Bin/minimal-oui.txt" ) or die "$!";
    local $/ = "";
    $fh->getline;
    my @samples = samples();
    while ( my $entry = $fh->getline ) {
        my $data = parse_oui_entry( $entry );
        my $ref = shift( @samples );
        delete $ref->{ $_ } for qw( _private );
        is_deeply( $data, $ref, "parse_oui_entry" );
    }
}

my @samples = reverse samples();
for my $oui ( map { $_->{ 'oui' } } @samples ) {
    my $ref = shift( @samples );
    delete $ref->{ '_private' };
    my $test = parse_oui_entry( "\n\n".oui_entry_for( $oui )."\n\n" );
    is_deeply( $ref, $test, "parse_oui_entry $oui" );
}


is( normalize_oui( $_ ), undef, "normalize_oui returns undef for $_" ) for qw(
    1234567890
);
