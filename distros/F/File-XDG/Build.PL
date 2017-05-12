use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'File::XDG',
   requires => {
       'Path::Class'   => 0,
       'File::HomeDir' => 0,
       'perl'          => '5.10.0',
   },
   build_requires => {
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
