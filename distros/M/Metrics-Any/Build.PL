use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Metrics::Any',
   requires => {
      'perl' => '5.014', # //, package NAME {BLOCK}
      'List::Util' => '1.29', # core since 5.20
   },
   test_requires => {
      'Test::Fatal' => 0,
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
