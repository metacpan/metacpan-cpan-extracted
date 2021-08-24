use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Future::IO::Impl::Glib',
   requires => {
      'perl' => '5.014',

      'Future' => 0,
      'Future::IO::ImplBase' => 0,
      'Glib' => 0,
   },
   test_requires => {
      'Test::Future::IO::Impl' => 0,
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
