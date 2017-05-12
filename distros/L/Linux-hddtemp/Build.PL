use Module::Build;

Module::Build->new(
  module_name => 'Linux::hddtemp',
  license => 'perl',
  create_makefile_pl => 'passthrough',
  requires => {
    'IO::Socket' => '1.00',
  },
)->create_build_script;
