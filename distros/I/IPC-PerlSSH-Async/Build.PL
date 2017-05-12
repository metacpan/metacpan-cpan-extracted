use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IPC::PerlSSH::Async',
   requires => {
      'IO::Async' => '0.21',
      'IO::Async::Process' => '0.37',
      'IPC::PerlSSH::Base' => '0.16',
   },
   build_requires => {
      'IO::Async::Test' => 0,
      'Test::More' => 0,
      'Test::Refcount' => 0,
      'Test::Warn' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
