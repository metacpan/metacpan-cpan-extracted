use Module::Build;
my $build = Module::Build->new(
  module_name => "Math::Fleximal",
  license => 'perl',
  create_makefile_pl => 'traditional',
)->create_build_script;
