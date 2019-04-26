use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Future::IO',
   requires => {
      'Future' => 0,
      'Struct::Dumb' => 0,
      'Time::HiRes' => 0,

      'perl' => '5.010', # //
   },
   test_requires => {
      'Test::Identity' => 0,
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
