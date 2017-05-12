
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Experimental module',
  'dist_author' => [
    'Kaare Rasmussen <kaare@cpan.org>'
  ],
  'dist_name' => 'Jet',
  'dist_version' => '0.001',
  'license' => 'perl',
  'module_name' => 'Jet',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'perl' => '5.006'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
