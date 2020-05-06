use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IO::Async::Loop::IO::Async',
   requires => {
      'IO::Async' => '0.49',
      'IO::Async::Timer::Absolute' => 0,
      'IO::Async::PID' => 0.32,
   },
   test_requires => {
      'Test::More' => '0.88',
      'IO::Async::LoopTests' => '0.76',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
