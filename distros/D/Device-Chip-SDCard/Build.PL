use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::SDCard',
   requires => {
      'perl' => '5.026',
      'Future::AsyncAwait' => '0.47', # toplevel await
      'Object::Pad' => '0.19',

      'Data::Bitfield' => 0,
      'Device::Chip' => 0,
   },
   test_requires => {
      'Test::Device::Chip::Adapter' => '0.05',
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
