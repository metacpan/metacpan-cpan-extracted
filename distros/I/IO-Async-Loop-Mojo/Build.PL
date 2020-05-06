use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IO::Async::Loop::Mojo',
   requires => {
      'IO::Async::Loop' => '0.49',
      'Mojolicious' => '2.65',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'IO::Async::LoopTests' => '0.76',
      'Test::More' => '0.88',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
