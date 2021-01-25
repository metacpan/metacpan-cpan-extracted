use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IO::Async::Loop::UV',
   requires => {
      'IO::Async::Loop' => '0.49',
      'UV' => '1.900',
   },
   test_requires => {
      'IO::Async::LoopTests' => '0.78', # checks _CAN_WATCH_ALL_PIDS
      'Test::More' => '0.88',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
