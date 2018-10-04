#!/usr/bin/perl

use strict;

use Test::More;

eval "use Tie::Sub";

plan skip_all => "Tie::Sub required" if $@;

plan tests => 4;

use_ok( 'Graphics::ColorNames', '2.10', qw( all_schemes ) );

tie my %colors, 'Graphics::ColorNames';

# Test handling of non-existent color names

ok( !defined $colors{NonExistentColorName} );
ok( !exists $colors{NonExistentColorName} );

# Test dynamic loading of scheme

my $colorobj = tied(%colors);
$colorobj->load_scheme(
    sub {
        return 0x123456;
    }
);
ok( $colors{NonExistentColorName} eq '123456' );
