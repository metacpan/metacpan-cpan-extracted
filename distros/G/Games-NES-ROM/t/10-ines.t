use strict;
use warnings;

use Test::More tests => 17;

BEGIN {
    use_ok( 'Games::NES::ROM::Format::INES' );
}

{
    eval {
        Games::NES::ROM::Format::INES->new(
            filename => 't/roms/notarom.nes' );
    };
    ok( $@ );
    like( $@, qr/not an ines rom/i );
}

{
    eval {
        Games::NES::ROM::Format::INES->new( filename => 't/roms/dne.nes' );
    };
    ok( $@ );
    like( $@, qr/unable to open/i );
}

{
    my $rom
        = Games::NES::ROM::Format::INES->new( filename => 't/roms/test.nes' );

    isa_ok( $rom, 'Games::NES::ROM' );

    is( $rom->id,        'NES' . chr( 26 ), 'id()' );
    is( $rom->filename,  't/roms/test.nes', 'filename()' );
    is( $rom->has_sram,  0,                 'has_sram()' );
    is( $rom->chr_count, 1,                 'chr_count()' );
    is( $rom->prg_count, 2,                 'prg_count()' );
    is( $rom->mapper,    0,                 'mapper()' );
    is( $rom->mirroring, 0,                 'mirroring()' );
    ok( !defined $rom->title, 'title()' );
    ok( !defined $rom->trainer, 'trainer()' );

SKIP: {
        eval { require Digest::CRC; };
        skip 'Digest::CRC not installed', 1 if $@;
        is( $rom->crc, '8e2bd25c', 'crc()' );
    }

SKIP: {
        eval { require Digest::SHA1; };
        skip 'Digest::SHA1 not installed', 1 if $@;
        is( $rom->sha1, '71fdb80c3583010422652cc5aae8e2e4131e49f3',
            'sha1()' );
    }
}
