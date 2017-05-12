use Test::More tests => 10;

BEGIN { 
    use_ok( 'Games::NES::Emulator' );
    use_ok( 'Games::NES::Emulator::CPU' );
    use_ok( 'Games::NES::Emulator::APU' );
    use_ok( 'Games::NES::Emulator::PPU' );
    use_ok( 'Games::NES::Emulator::PPU::Memory' );
    use_ok( 'Games::NES::Emulator::Input' );
    use_ok( 'Games::NES::Emulator::Mapper' );
    use_ok( 'Games::NES::Emulator::Mappers::Mapper0' );
    use_ok( 'CPU::Emulator::6502' );
    use_ok( 'CPU::Emulator::6502::Addressing' );
    # test ops?
}
