
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Dist::Zilla according to wolverian',
  'dist_author' => [
    'Ilmari Vacklin <ilmari.vacklin@cs.helsinki.fi>'
  ],
  'dist_name' => 'Dist-Zilla-PluginBundle-Author-WOLVERIAN',
  'dist_version' => 'v0.0.8',
  'license' => 'perl',
  'module_name' => 'Dist::Zilla::PluginBundle::Author::WOLVERIAN',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Dist::Zilla::Plugin::Authority' => '0',
    'Dist::Zilla::Plugin::AutoPrereqs' => '0',
    'Dist::Zilla::Plugin::Bugtracker' => '0',
    'Dist::Zilla::Plugin::EOLTests' => '0',
    'Dist::Zilla::Plugin::Git' => '0',
    'Dist::Zilla::Plugin::GithubMeta' => '0',
    'Dist::Zilla::Plugin::InstallGuide' => '0',
    'Dist::Zilla::Plugin::MetaJSON' => '0',
    'Dist::Zilla::Plugin::MetaTests' => '0',
    'Dist::Zilla::Plugin::MinimumPerl' => '0',
    'Dist::Zilla::Plugin::MinimumVersionTests' => '0',
    'Dist::Zilla::Plugin::ModuleBuild' => '0',
    'Dist::Zilla::Plugin::PodCoverageTests' => '0',
    'Dist::Zilla::Plugin::PodSyntaxTests' => '0',
    'Dist::Zilla::Plugin::PodWeaver' => '0',
    'Dist::Zilla::Plugin::Repository' => '0',
    'Moose::Autobox' => '0',
    'MooseX::Declare' => '0',
    'perl' => '5.006'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
