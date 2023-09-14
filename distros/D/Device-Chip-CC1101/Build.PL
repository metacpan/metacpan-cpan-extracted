use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::CC1101',
   requires => {
      'perl' => '5.026', # postfix-deref, signatures
      'Future::AsyncAwait' => '0.47', # toplevel await
      'Object::Pad' => '0.800',

      'Data::Bitfield' => '0.04',
      'Device::Chip' => 0,
      'Future::IO' => 0,
   },
   test_requires => {
      'Test::Device::Chip::Adapter' => 0,
      'Test2::V0' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
