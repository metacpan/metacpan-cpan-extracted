use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IO::Async::Loop::POE',
   requires => {
      'IO::Async' => '0.49',
      'POE' => '1.293',
   },
   test_requires => {
      'IO::Async::LoopTests' => '0.76',
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
