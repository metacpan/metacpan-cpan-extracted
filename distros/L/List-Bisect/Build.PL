
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'split a list in to two parts by way of a grep like block',
  'dist_author' => [
    'Ben Hengst <notbenh@cpan.org>'
  ],
  'dist_name' => 'List-Bisect',
  'dist_version' => '0.002',
  'license' => 'perl',
  'module_name' => 'List::Bisect',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Exporter' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
