use Test::More tests => 10;

use_ok( 'Games::NES::Emulator' );

my $emu = Games::NES::Emulator->new;
isa_ok( $emu, 'Games::NES::Emulator' );
isa_ok( $emu->cpu, 'Games::NES::Emulator::CPU' );
isa_ok( $emu->apu, 'Games::NES::Emulator::APU' );
isa_ok( $emu->ppu, 'Games::NES::Emulator::PPU' );
isa_ok( $emu->ppu->VRAM, 'Games::NES::Emulator::PPU::Memory' );

for( @{ $emu->inputs } ) {
    isa_ok( $_, 'Games::NES::Emulator::Input' );
}

SKIP: {
    my $rom = $ENV{ TEST_ROM };
    skip 'No ROM specified in $ENV{ TEST_ROM }', 2 unless $rom;

    $emu->load_rom( $rom );
    isa_ok( $emu->rom, 'Games::NES::ROM' );
    isa_ok( $emu->mapper, 'Games::NES::Emulator::Mapper' );
};


