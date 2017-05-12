use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip',
   requires => {
      'Future' => '0.26',
      'List::Util' => '1.33',
      'Test::Builder' => 0,

      'perl' => '5.010', #  //
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Builder::Tester' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
