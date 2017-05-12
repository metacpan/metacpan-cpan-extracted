use inc::Module::Install;

name 'KSx-Searcher-Abstract';
all_from 'lib/KSx/Searcher/Abstract.pm';

requires 'KinoSearch'               => '0.20_04';

build_requires 'Test::More'         => '0.62';

auto_install;
WriteAll;
