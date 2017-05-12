#!/usr/bin/env perl
use strict; use warnings;
use FindBin qw( $Bin );
BEGIN {
    require "$Bin/device-oui-test-lib.pl";
    require "$Bin/fake-lwp.pl";
}

plan tests => 183;

# Setup for offline testing
Device::OUI->cache_file( "$Bin/minimal-oui.txt" );
rm( "$Bin/test-cache.db" );
Device::OUI->cache_db( "$Bin/test-cache" );
Device::OUI->search_url( undef );
Device::OUI->file_url( undef );

# Simple cache test

for my $sample ( samples() ) {
    my $oui = Device::OUI->new( $sample->{ 'oui' } );
    ok( $oui, "Created new Device::OUI for $sample->{ 'oui' }" );
    isa_ok( $oui, 'Device::OUI' );
    my @compare = mutate_oui( $sample->{ 'oui' } );
    for my $compare ( @compare ) {
        my $new = Device::OUI->new( $compare );
        ok( $new == $oui, "$new == $oui" );
        ok( $new eq $oui, "$new eq $oui" );
    }
    for my $x (qw( oui company_id organization address )) {
        is( $oui->$x(), $sample->{ $x }, "$x matches" );
    }
    is( $oui->is_private, $sample->{ '_private' } || 0, "is_private" );
}

{
    Device::OUI->cache_db( undef );
    my $oui = Device::OUI->new( '00-1C-42' );
    is(
        $oui->organization, 'Parallels, Inc.',
        'Can perform a lookup with a cache file but no cache db',
    );
}

{
    Device::OUI->cache_db( undef );
    Device::OUI->cache_file( "$Bin/minimal-oui.txt" );
    my $oui = Device::OUI->new( '00-1C-42' );
    is(
        $oui->organization, 'Parallels, Inc.',
        'Can perform a lookup with a cache file but without cache db',
    );
}
