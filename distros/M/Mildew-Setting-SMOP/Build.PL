
use strict;
use warnings;

use Module::Build 0.3601;
use lib 'inc'; use MyBuilder;

my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'the setting for mildew compiled for SMOP',
  'dist_author' => [
    'Pawel Murias <pawelmurias@gmail.com>'
  ],
  'dist_name' => 'Mildew-Setting-SMOP',
  'dist_version' => '0.03',
  'license' => 'artistic_2',
  'module_name' => 'Mildew::Setting::SMOP',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Mildew' => '0.05',
    'SMOP' => '0.06'
  },
  'script_files' => []
);


my $build = MyBuilder->new(%module_build_args);

$build->create_build_script;
