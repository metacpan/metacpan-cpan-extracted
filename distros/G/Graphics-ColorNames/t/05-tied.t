#!/usr/bin/perl

use Test::Most;

use lib 't/lib';

use_ok( 'Graphics::ColorNames', '3.3', qw( hex2tuple tuple2hex ) );

tie my %colors, 'Graphics::ColorNames';
ok( tied %colors );

my $count = 0;
foreach my $name ( keys %colors ) {
    my @RGB = hex2tuple( $colors{$name} );
    $count++, if ( tuple2hex(@RGB) eq $colors{$name} );
}
ok( $count == keys %colors );

$count = 0;
foreach my $name ( keys %colors ) {
    $count++, if ( $colors{ lc($name) } eq $colors{ uc($name) } );
}
ok( $count == keys %colors );

$count = 0;
foreach my $name ( keys %colors ) {
    $count++, if ( exists( $colors{$name} ) );
}
ok( $count == keys %colors );

$count = 0;
foreach my $name ( keys %colors ) {
    my $rgb = $colors{$name};
    $count++, if ( defined $colors{$rgb} );
    $count++, if ( defined $colors{ "\x23" . $rgb } );
}
ok( $count == ( 2 * ( keys %colors ) ) );

# Test CLEAR, DELETE and STORE as returning errors

dies_ok { undef %colors } "undef %colors";

dies_ok { %colors = (); } "%colors = ()";

dies_ok { $colors{MyCustomColor} = 'FFFFFF'; } "STORE";

dies_ok { delete( $colors{MyCustomColor} ); } "DELETE";

# Test RGB values being passed through

foreach my $rgb (
    qw(
    000000 000001 000010 000100 001000 010000 100000
    111111 123abc abc123 123ABC ABC123 abcdef ABCDEF
    )
  )
{
    ok( $colors{ "\x23" . $rgb } eq lc($rgb) );
    ok( $colors{ "0x" . $rgb } eq lc($rgb) );
    ok( $colors{$rgb} eq lc($rgb) );
}

# Test using multiple schemes, with issues in overlapping

tie my %colors3, 'Graphics::ColorNames', qw( X Test );

tie my %colors4, 'Graphics::ColorNames', qw( Test X );

# Test precedence

ok( $colors{DarkGreen} eq '006400' );     # DarkGreen in X
ok( $colors3{DarkGreen} eq '006400' );    # DarkGreen in X
ok( $colors4{DarkGreen} eq '008000' );    # DarkGreen in Test

# Test handling of non-existent color names

ok( !defined $colors{NonExistentColorName} );
ok( !exists $colors{NonExistentColorName} );

done_testing;
