use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::Adapter::UART',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.70',

      'Device::Chip::Adapter' => 0,
      'Future' => 0,
      'Future::Buffer' => 0,
      'Future::IO' => 0.04,
      'IO::Termios' => 0,
   },
   test_requires => {
      'Future::AsyncAwait' => 0,
      'Test::Future::IO' => '0.05',
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004',  # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
