use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::INA219',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.800',
      'Future::AsyncAwait' => '0.47', # toplevel await

      'Data::Bitfield' => 0,
      'Device::Chip' => '0.04',
      'Device::Chip::Base::RegisteredI2C' => '0.10',
   },
   build_requires => {
      'Test::Device::Chip::Adapter' => 0,
      'Test2::V0' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
