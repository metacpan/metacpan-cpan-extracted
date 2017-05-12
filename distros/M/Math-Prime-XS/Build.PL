# Note: this file has been initially created by Make::Build::Convert 0.20_05

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Math::Prime::XS',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/Math/Prime/XS.pm',
   requires => {
                 'boolean' => 0,
                 'Carp' => 0,
                 'Exporter' => 0,
                 'Params::Validate' => 0,
                 'Scalar::Util' => 0,
                 'XSLoader' => 0,
               },
   build_requires => { 'Test::More' => 0 },
   recommends => {
                   'Test::Pod' => '1.14',
                   'Test::Pod::Coverage' => '1.04',
                 },
   xs_files => { 'XS.xs' => 'lib/Math/Prime/XS.xs' },
   include_dirs => [ '.' ],
   license => 'perl',
   create_readme => 1,
   create_makefile_pl => 'traditional',
  );

$build->create_build_script;
