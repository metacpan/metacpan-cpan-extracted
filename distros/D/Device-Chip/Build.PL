use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip',
   requires => {
      'perl' => '5.026', # signatures in Object::Pad
      'Future::AsyncAwait' => '0.47', # toplevel await
      'Object::Pad' => '0.800',
      'Object::Pad::ClassAttr::Struct' => '0.05',

      'Future' => '0.26',
      'Future::Buffer' => 0,
      'List::Util' => '1.33',
      'Test::Builder' => 0,
      'Test::ExpectAndCheck::Future' => '0.04',
   },
   test_requires => {
      'Test2::V0' => 0,
      'Test::Builder::Tester' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
