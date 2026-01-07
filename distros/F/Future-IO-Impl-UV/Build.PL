use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Future::IO::Impl::UV',
   requires => {
      'perl' => '5.020',

      'Future' => 0,
      'Future::IO::ImplBase' => '0.17',
      'UV' => "1.900",
   },
   test_requires => {
      'Test::Future::IO::Impl' => '0.15',
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
