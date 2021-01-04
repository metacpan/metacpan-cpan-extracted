use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::HTU21D',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.19',

      'Data::Bitfield' => '0.02',
      'Device::Chip' => '0.03',
      'Device::Chip::Sensor' => 0,
      'Future::AsyncAwait' => '0.47', # toplevel await
      'Future::Mutex' => '0.47', # weaken() bugfix
   },
   test_requires => {
      'Test::Device::Chip::Adapter' => '0.09',
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   extra_manify_args => {
      utf8 => 1, # We have UTF-8 manpages
   },
);

$build->create_build_script;
