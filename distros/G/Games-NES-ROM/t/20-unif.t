use strict;
use warnings;

use Test::More tests => 21;

BEGIN {
    use_ok( 'Games::NES::ROM::Format::UNIF' );
}

{
    eval {
        Games::NES::ROM::Format::UNIF->new(
            filename => 't/roms/notarom.nes' );
    };
    ok( $@ );
    like( $@, qr/not a unif rom/i );
}

{
    eval {
        Games::NES::ROM::Format::UNIF->new( filename => 't/roms/dne.nes' );
    };
    ok( $@ );
    like( $@, qr/unable to open/i );
}

{
    my $rom = Games::NES::ROM::Format::UNIF->new(
        filename => 't/roms/test.unif' );

    isa_ok( $rom, 'Games::NES::ROM' );

    is( $rom->id,        'UNIF',             'id()' );
    is( $rom->filename,  't/roms/test.unif', 'filename()' );
    is( $rom->has_sram,  0,                  'has_sram()' );
    is( $rom->chr_count, 1,                  'chr_count()' );
    is( $rom->prg_count, 1,                  'prg_count()' );
    is( $rom->mapper,    'NES-NROM-128',     'mapper()' );
    is( $rom->mirroring, 1,                  'mirroring()' );
    is( $rom->title,     'Scanline demo',    'title()' );
    is( $rom->revision,  7,                  'revision()' );
    ok( !defined $rom->comments, 'comments()' );
    is( $rom->tvci, 0, 'tvci()' );
    ok( !defined $rom->controller, 'controller()' );
    is( $rom->has_vror, 0, 'has_vror()' );

SKIP: {
        eval { require Digest::CRC; };
        skip 'Digest::CRC not installed', 1 if $@;
        is( $rom->crc, 'f944cedb', 'crc()' );
    }

SKIP: {
        eval { require Digest::SHA1; };
        skip 'Digest::SHA1 not installed', 1 if $@;
        is( $rom->sha1, 'c2539fa1286c6b5c3ef6d22638da1b7940f77fce',
            'sha1()' );
    }
}
