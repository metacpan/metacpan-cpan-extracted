use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Serial::SLuRM',
   requires => {
      'perl' => '5.026',
      'Future::AsyncAwait' => 0,
      'Object::Pad' => '0.800',
      'Syntax::Keyword::Match' => 0,

      'Digest::CRC' => 0,
      'Future::Buffer' => '0.03',
      'Future::IO' => 0,
      'IO::Termios' => 0,
   },
   test_requires => {
      'Future::Buffer' => '0.05',
      'Test::ExpectAndCheck::Future' => '0.04',
      'Test::Future::IO' => '0.05',
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
