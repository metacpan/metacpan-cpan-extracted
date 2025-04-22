use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IO::Async::Loop::Epoll',
   requires => {
      'IO::Async' => '0.24',
      'Linux::Epoll' => '0.005',
      'Struct::Dumb' => 0,

      'perl' => '5.014',
   },
   configure_requires => {
      'Module::Build' => '0.4004',  # test_requires
   },
   test_requires => {
      'IO::Async::LoopTests' => '0.804',
      'Test2::V0' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
