use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::TCS3472x',
   requires => {
      'Data::Bitfield' => '0.03',
      'Future' => 0,
      'Future::AsyncAwait' => '0.47', # toplevel await
      'Object::Pad' => '0.57',

      'perl' => '5.026', # signatures in Object::Pad
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
