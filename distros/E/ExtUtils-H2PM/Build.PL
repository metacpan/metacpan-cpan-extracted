use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'ExtUtils::H2PM',
   requires => {
      'perl' => '5.014',

      'Exporter' => '5.57',
      'ExtUtils::CBuilder' => 0,
      'List::Util' => '1.39',
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
