#!/usr/bin/perl

use strict;

use Test::More tests => 19;

use_ok( 'Graphics::ColorNames', 2.1002, qw( hex2tuple tuple2hex ) );

tie my %colors, 'Graphics::ColorNames', 'X';
ok( tied %colors );

is( scalar(keys %colors), 676 );    #

my $count = 0;
foreach my $name ( keys %colors ) {
    my @RGB = hex2tuple( $colors{$name} );
    $count++, if ( tuple2hex(@RGB) eq $colors{$name} );
}
ok( $count == keys %colors );

foreach my $ad (qw( royal dodger slate sky steel )) {
    foreach my $col (qw( blue )) {
        ok( exists $colors{"$ad$col"} );
        ok( $colors{"$ad$col"} eq $colors{"$ad $col"},  "$ad $col" );
        ok( $colors{"$ad-$col"} eq $colors{"$ad $col"}, "$ad $col" );
    }
}
