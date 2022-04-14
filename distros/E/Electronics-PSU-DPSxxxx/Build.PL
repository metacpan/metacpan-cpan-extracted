use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Electronics::PSU::DPSxxxx',
   requires => {
      'perl' => '5.026',
      'Future::AsyncAwait' => 0,
      'Object::Pad' => 0,

      'Future::IO' => 0,
      'IO::Termios' => 0,
   },
   test_requires => {
      'Test::Future::IO' => 0,
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
