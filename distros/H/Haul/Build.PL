use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license     => 'perl',
  module_name => 'Haul',
  requires    => {
    'CPAN::DistnameInfo' => 0,
    'IPC::Run3' => 0,
    'Module::Depends' => '0.03',
    'Test::More' => '0.01',
  },
);
$build->create_build_script;
