use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::INA219',
   requires => {
      'Data::Bitfield' => 0,
      'Device::Chip' => '0.04',
      'Device::Chip::Base::RegisteredI2C' => '0.10',
   },
   build_requires => {
      'Test::Device::Chip::Adapter' => 0,
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
