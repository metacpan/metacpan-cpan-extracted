use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => "Device::Chip::PMS5003",

   requires => {
      'perl' => '5.026', # signatures in Object::Pad
      'Future::AsyncAwait' => '0.47',
      'Object::Pad' => '0.800',

      'Device::Chip' => '0.10',
      'Device::Chip::Sensor' => '0.23',
   },
   test_requires => {
      'Test::Device::Chip::Adapter' => '0.26',
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
