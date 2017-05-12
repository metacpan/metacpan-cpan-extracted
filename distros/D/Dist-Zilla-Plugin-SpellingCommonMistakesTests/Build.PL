
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Dist::Zilla::Plugin::Bootstrap::lib' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Release tests for common POD spelling mistakes',
  'dist_author' => [
    'Adam Lesperance <lespea@gmail.com>'
  ],
  'dist_name' => 'Dist-Zilla-Plugin-SpellingCommonMistakesTests',
  'dist_version' => '1.001000',
  'license' => 'perl',
  'module_name' => 'Dist::Zilla::Plugin::SpellingCommonMistakesTests',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Dist::Zilla::Plugin::InlineFiles' => '0',
    'Moose' => '0',
    'Pod::Spell::CommonMistakes' => '0',
    'Test::Pod::Spelling::CommonMistakes' => '0',
    'perl' => '5.008',
    'utf8' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
