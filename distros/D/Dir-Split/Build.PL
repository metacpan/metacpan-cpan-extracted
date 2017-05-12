## Created by make2build 0.16

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Dir::Split',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/Dir/Split.pm',
   requires => {
                 'Carp' => 0,
                 'File::Basename' => 0,
                 'File::Copy' => 0,
                 'File::Find' => 0,
                 'File::Path' => 0,
                 'File::Spec' => 0,
                 'SelfLoader' => 0,
               },
   build_requires => {
                       'File::Temp' => 0,
                       'Test::More' => 0,
                     },
   recommends => {
                   'Test::Pod' => '1.14',
                   'Test::Pod::Coverage' => '1.04',
                 },
   license => 'perl',
   create_readme => 1,
   create_makefile_pl => 'traditional',
  );

$build->create_build_script;
