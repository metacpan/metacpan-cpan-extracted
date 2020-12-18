use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::nRF24L01P',
   requires => {
      'perl' => '5.026',
      'Future::AsyncAwait' => '0.38', # async method
      'Object::Pad' => '0.19', # async method

      'Data::Bitfield' => 0,
      'Device::Chip' => 0,
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Device::Chip::Adapter' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
