use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::AVR_HVSP',
   requires => {
      'Device::Chip' => '0.04',
      'Struct::Dumb' => 0,
   },
   test_requires => {
      'Test::Device::Chip::Adapter' => 0,
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
