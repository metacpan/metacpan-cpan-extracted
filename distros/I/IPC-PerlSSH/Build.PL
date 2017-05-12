use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IPC::PerlSSH',
   dist_version_from => 'lib/IPC/PerlSSH.pm',
   requires => {
      'Exporter' => '5.57',
      'IPC::Open2' => 0,
   },
   build_requires => {
      'File::Temp' => 0,
      'IO::Handle' => 0,
      'Test::Fatal' => 0,
      'Test::More' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
