
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
  'dist_abstract' => 'Generate a Table of Contents for HTML documents.',
  'dist_author' => [
    'Kathryn Andersen'
  ],
  'dist_name' => 'HTML-GenToc',
  'dist_version' => '3.20',
  'license' => 'gpl',
  'module_name' => 'HTML::GenToc',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Data::Dumper' => '0',
    'File::Basename' => '0',
    'Getopt::Long' => '2.34',
    'HTML::Entities' => '0',
    'HTML::LinkList' => '0',
    'HTML::SimpleParse' => '0',
    'Pod::Usage' => '0'
  },
  'script_files' => [
    'scripts/hypertoc'
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
