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
   test_requires => { 'Test::More' => 0 },
   license => 'perl',
   create_readme => 1,
   meta_merge => {
       resources => {
           repository => 'https://github.com/stsc/LaTeX-TOM',
       },
   },
  );

$build->create_build_script;
