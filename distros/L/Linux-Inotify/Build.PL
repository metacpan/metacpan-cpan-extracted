use Module::Build;

my $build = new Module::Build
 (
  module_name        => 'Linux::Inotify',
  license            => 'perl',
  requires           => {
                         perl               => '5.6.1',
                         POSIX              => 0,
                         Carp               => 0,
                        },
  create_makefile_pl => 'passthrough',
  create_readme      => 1,
 );
$build->create_build_script;
$build->create_makefile_pl;
