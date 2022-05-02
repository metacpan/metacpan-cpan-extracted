use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => "Device::Chip::AnalogConverters",

   requires => {
      'perl' => '5.026', # signatures in Object::Pad
      'Future::AsyncAwait' => '0.47', # toplevel await
      'Object::Pad' => '0.57',

      'Data::Bitfield' => '0.02',
      'Device::Chip' => '0.10',
      'Future::IO' => 0,
   },
   test_requires => {
      'Test::Device::Chip::Adapter' => '0.14',
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
