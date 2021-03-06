use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IO::Async::Resolver::StupidCache',
   requires => {
      'Future' => '0.30',
      'IO::Async::Notifier' => 0,
      'IO::Async::Resolver' => 0,
      'Struct::Dumb' => 0,
   },
   test_requires => {
      'IO::Async::Loop' => '0.62',
      'IO::Async::Test' => 0,
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
