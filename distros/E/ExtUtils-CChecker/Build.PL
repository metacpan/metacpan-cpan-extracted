use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'ExtUtils::CChecker',
   requires => {
      'ExtUtils::CBuilder' => 0,
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Fatal' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
