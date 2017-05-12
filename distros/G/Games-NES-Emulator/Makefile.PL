use inc::Module::Install 0.65;

name 'Games-NES-Emulator';
all_from 'lib/Games/NES/Emulator.pm';

requires 'Class::Accessor::Fast';
requires 'Games::NES::ROM';
requires 'Scalar::Util';
requires 'Module::Pluggable::Object';
requires 'Text::SimpleTable';
requires 'Test::More';

auto_install;
WriteAll;
