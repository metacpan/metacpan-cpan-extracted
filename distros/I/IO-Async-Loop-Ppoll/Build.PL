use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IO::Async::Loop::Ppoll',
   requires => {
      'IO::Async' => 0.24,
      'IO::Async::Loop::Poll' => '0.76',
      'IO::Ppoll' => 0.05,
   },
   test_requires => {
      'IO::Async::LoopTests' => '0.76',
      'Test::More' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
