use inc::Module::Install;

name 'KSx-IndexManager';
all_from 'lib/KSx/IndexManager.pm';

requires 'KinoSearch'               => '0.20_04';
requires 'Data::OptList'            => '0.101';
requires 'Module::Pluggable'        => '3.1';
requires 'Carp::Clan'               => '5.3';
requires 'Class::Accessor::Grouped' => '0.06000';

build_requires 'Test::MockObject'   => '1.06';
build_requires 'Test::More'         => '0.62';

auto_install;
WriteAll;
