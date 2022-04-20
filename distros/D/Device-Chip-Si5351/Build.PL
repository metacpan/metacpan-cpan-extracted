use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::Si5351',
   requires => {
      'perl' => '5.026',
      'Future::AsyncAwait' => '0.38',
      'Object::Pad' => 0.57,

      'Data::Bitfield' => 0,
      'Device::Chip::Base::RegisteredI2C' => '0.21',
   },
   test_requires => {
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
