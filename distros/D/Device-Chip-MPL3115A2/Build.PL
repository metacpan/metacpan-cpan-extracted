use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::MPL3115A2',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.57',
      'Future::AsyncAwait' => '0.47', # toplevel await

      'Data::Bitfield' => '0.02',
      'Device::Chip::Base::RegisteredI2C' => '0.03',
      'Device::Chip::Sensor' => '0.23',
      'Future::Mutex' => '0.47', # weaken() bugfix
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Device::Chip::Adapter' => '0.24',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
