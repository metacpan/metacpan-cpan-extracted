use strict;
use warnings;

use Module::Build;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $build = Module::Build->new
  (
   module_name => 'Getopt::Mixed::Help',
   dist_version_from => 'lib/Getopt/Mixed/Help.pm', # finds $VERSION
   license => 'perl',
   create_readme => 0,
   create_makefile_pl => 'traditional',
   requires => { perl => '5.8.9',
                 'Getopt::Long' => 0
	       },
   recommends => { 'Test::Pod' => 0, 'Test::Pod::Coverage' => 0 },
  );

$build->create_build_script;
