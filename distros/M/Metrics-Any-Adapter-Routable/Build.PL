use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Metrics::Any::Adapter::Routable',
   requires => {
      'List::Util' => '1.39',
      'Metrics::Any::Adapter' => '0.06',

      'perl' => '5.024',
   },
   test_requires => {
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
