use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IO::Async::Loop::IO::Async',
   requires => {
      'IO::Async' => 0.24,
      'IO::Async::Timer::Absolute' => 0,
      'IO::Async::PID' => 0.32,
   },
   build_requires => {
      'Test::More' => 0,
      'IO::Async::LoopTests' => '0.24',
   },
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
