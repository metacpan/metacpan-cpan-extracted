use inc::Module::Install;

name        'Device-USB-TranceVibrator';
all_from    'lib/Device/USB/TranceVibrator.pm';

requires 'UNIVERSAL::require'    => 0;

build_requires 'Test::More'      => 0;
build_requires 'Test::Base'      => 0;

requires       'Device::USB'     => 0;

use_test_base;
auto_install;
WriteAll;

