use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::SDCard',
   requires => {
      'Data::Bitfield' => 0,
      'Device::Chip' => 0,
      'Future::Utils' => 0,
   },
   test_requires => {
      'Test::Device::Chip::Adapter' => '0.05',
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
