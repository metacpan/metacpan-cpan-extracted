
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Logging to Growl',
  'dist_author' => [
    'Kang-min Liu <gugod@gugod.org>'
  ],
  'dist_name' => 'Log-Dispatch-Growl',
  'dist_version' => '1.0.0',
  'license' => 'mit',
  'module_name' => 'Log::Dispatch::Growl',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'File::Basename' => '0',
    'Growl::Any' => '0',
    'Log::Dispatch::Output' => '0',
    'Params::Validate' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
