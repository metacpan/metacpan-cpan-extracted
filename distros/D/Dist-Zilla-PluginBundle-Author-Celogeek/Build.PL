
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Dist::Zilla like Celogeek",
  "dist_author" => [
    "celogeek <me\@celogeek.com>"
  ],
  "dist_name" => "Dist-Zilla-PluginBundle-Author-Celogeek",
  "dist_version" => "1.1",
  "license" => "perl",
  "module_name" => "Dist::Zilla::PluginBundle::Author::Celogeek",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Class::MOP" => 0,
    "Devel::Cover" => 0,
    "Dist::Zilla::App::Command::cover" => 0,
    "Dist::Zilla::Plugin::AutoPrereqs" => 0,
    "Dist::Zilla::Plugin::CheckChangeLog" => 0,
    "Dist::Zilla::Plugin::Git::NextVersion" => 0,
    "Dist::Zilla::Plugin::MetaConfig" => 0,
    "Dist::Zilla::Plugin::MetaJSON" => 0,
    "Dist::Zilla::Plugin::MetaResourcesFromGit" => 0,
    "Dist::Zilla::Plugin::MinimumPerl" => 0,
    "Dist::Zilla::Plugin::ModuleBuild" => 0,
    "Dist::Zilla::Plugin::NextRelease" => 0,
    "Dist::Zilla::Plugin::OurPkgVersion" => 0,
    "Dist::Zilla::Plugin::PerlTidy" => 0,
    "Dist::Zilla::Plugin::PodCoverageTests" => 0,
    "Dist::Zilla::Plugin::PodWeaver" => 0,
    "Dist::Zilla::Plugin::Prepender" => 0,
    "Dist::Zilla::Plugin::Prereqs" => 0,
    "Dist::Zilla::Plugin::PruneFiles" => 0,
    "Dist::Zilla::Plugin::ReadmeMarkdownFromPod" => 0,
    "Dist::Zilla::Plugin::ReportVersions" => 0,
    "Dist::Zilla::Plugin::Run::BeforeRelease" => 0,
    "Dist::Zilla::Plugin::Test::Compile" => 0,
    "Dist::Zilla::Plugin::Test::Perl::Critic" => 0,
    "Dist::Zilla::Plugin::Test::UnusedVars" => 0,
    "Dist::Zilla::PluginBundle::Filter" => 0,
    "Dist::Zilla::PluginBundle::Git" => 0,
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Dist::Zilla::Role::PluginBundle::PluginRemover" => 0,
    "IO::All" => "0.45",
    "Moose" => 0,
    "Pod::Coverage::TrustPod" => 0,
    "Pod::Weaver::Config::Assembler" => 0,
    "Test::Perl::Critic" => 0,
    "Test::Pod::Coverage" => "1.08",
    "namespace::autoclean" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Carp" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Scalar::Util" => 0,
    "Test::More" => "0.94",
    "perl" => "5.006"
  }
);


my %fallback_build_requires = (
  "Carp" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.3601",
  "Scalar::Util" => 0,
  "Test::More" => "0.94",
  "perl" => "5.006"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
