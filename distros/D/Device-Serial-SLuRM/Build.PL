use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Serial::SLuRM',
   requires => {
      'perl' => '5.026',
      'Future::AsyncAwait' => 0,
      'Object::Pad' => '0.76',
      'Syntax::Keyword::Match' => 0,

      'Digest::CRC' => 0,
      'Future::Buffer' => '0.03',
      'Future::IO' => 0,
      'IO::Termios' => 0,
   },
   test_requires => {
      'Test::ExpectAndCheck::Future' => '0.04',
      'Test::Future::IO' => '0.05',
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
