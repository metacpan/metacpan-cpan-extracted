use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::BNO055',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.57',

      'Data::Bitfield' => '0.03',
      'Device::Chip::Base::RegisteredI2C' => '0.12',
      'Future::AsyncAwait' => '0.47', # toplevel await
   },
   test_requires => {
      'Test::Device::Chip::Adapter' => 0,
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
