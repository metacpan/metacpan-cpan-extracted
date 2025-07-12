use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Future::Selector',
   requires => {
      'perl' => '5.026',
      'Future::AsyncAwait' => '0.44',
      'Object::Pad' => '0.800',
      'Sublike::Extended' => '0.29',

      'Scalar::Util' => 0,
   },
   test_requires => {
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
