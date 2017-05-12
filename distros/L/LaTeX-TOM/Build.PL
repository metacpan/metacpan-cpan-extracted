## Created by make2build 0.17

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'LaTeX::TOM',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/LaTeX/TOM.pm',
   requires => {
                 'Carp' => 0,
                 'File::Basename' => 0,
               },
   build_requires => { 'Test::More' => 0 },
   license => 'perl',
   create_readme => 1,
   create_makefile_pl => 'traditional',
  );

$build->create_build_script;
