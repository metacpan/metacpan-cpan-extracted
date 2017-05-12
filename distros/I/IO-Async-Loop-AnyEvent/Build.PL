use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IO::Async::Loop::AnyEvent',
   requires => {
      'IO::Async' => '0.24',
      'AnyEvent' => 0,
   },
   build_requires => {
      'Test::More' => 0,
      'IO::Async::LoopTests' => '0.43',
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
