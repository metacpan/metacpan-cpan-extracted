use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::AVR::UPDI',
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      'Future::AsyncAwait' => 0,
      'Future::IO' => '0.03',
      'Struct::Dumb' => 0,
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::EasyMock' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
