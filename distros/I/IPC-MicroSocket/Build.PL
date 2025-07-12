use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IPC::MicroSocket',
   requires => {
      'perl' => '5.036',
      'Future::AsyncAwait' => 0,
      'Object::Pad' => '0.817',
      'Sublike::Extended' => '0.29',
      'Syntax::Keyword::Match' => 0,

      'Future::Buffer' => '0.03',
      'Future::IO' => 0,
      'Future::Selector' => '0.02',
   },
   test_requires => {
      'Test::Future::IO' => '0.06',
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
