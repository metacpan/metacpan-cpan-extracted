use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
  ( module_name     => 'HTTP::CheckProxy',
    license         => 'gpl',
    requires => {'LWP::UserAgent' => '2.024'},
    create_makefile_pl => 'passthrough',
    create_readme => 1,
    sign =>1
  )->create_build_script;
