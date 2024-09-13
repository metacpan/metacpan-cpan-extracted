use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Metrics::Any::Adapter::Routable',
   requires => {
      'perl' => '5.024',
      'meta' => '0.008',

      'List::Util' => '1.39',
      'Metrics::Any::Adapter' => '0.06',
      'Syntax::Keyword::Try' => '0.18',
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
