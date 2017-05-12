
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "My standard dzil config.",
  "dist_author" => [
    "George Hartzell <hartzell\@cpan.org>",
    "David Golden <dagolden\@cpan.org>"
  ],
  "dist_name" => "Dist-Zilla-PluginBundle-HARTZELL",
  "dist_version" => "0.008",
  "license" => "perl",
  "module_name" => "Dist::Zilla::PluginBundle::HARTZELL",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dist::Zilla" => "4.3",
    "Dist::Zilla::Plugin::AutoMetaResources" => 0,
    "Dist::Zilla::Plugin::AutoPrereqs" => 0,
    "Dist::Zilla::Plugin::CheckChangesHasContent" => 0,
    "Dist::Zilla::Plugin::CheckExtraTests" => 0,
    "Dist::Zilla::Plugin::CheckMetaResources" => "0.001",
    "Dist::Zilla::Plugin::CheckPrereqsIndexed" => "0.002",
    "Dist::Zilla::Plugin::ConfirmRelease" => 0,
    "Dist::Zilla::Plugin::CopyFilesFromBuild" => 0,
    "Dist::Zilla::Plugin::ExecDir" => 0,
    "Dist::Zilla::Plugin::FakeRelease" => 0,
    "Dist::Zilla::Plugin::Git::Check" => 0,
    "Dist::Zilla::Plugin::Git::Commit" => 0,
    "Dist::Zilla::Plugin::Git::GatherDir" => 0,
    "Dist::Zilla::Plugin::Git::NextVersion" => 0,
    "Dist::Zilla::Plugin::Git::Push" => 0,
    "Dist::Zilla::Plugin::Git::Tag" => 0,
    "Dist::Zilla::Plugin::License" => 0,
    "Dist::Zilla::Plugin::Manifest" => 0,
    "Dist::Zilla::Plugin::ManifestSkip" => 0,
    "Dist::Zilla::Plugin::MetaJSON" => 0,
    "Dist::Zilla::Plugin::MetaNoIndex" => 0,
    "Dist::Zilla::Plugin::MetaProvides::Package" => "1.14",
    "Dist::Zilla::Plugin::MetaTests" => 0,
    "Dist::Zilla::Plugin::MetaYAML" => 0,
    "Dist::Zilla::Plugin::MinimumPerl" => 0,
    "Dist::Zilla::Plugin::ModuleBuild" => 0,
    "Dist::Zilla::Plugin::NextRelease" => 0,
    "Dist::Zilla::Plugin::PkgVersion" => 0,
    "Dist::Zilla::Plugin::PodCoverageTests" => 0,
    "Dist::Zilla::Plugin::PodSyntaxTests" => 0,
    "Dist::Zilla::Plugin::PodWeaver" => 0,
    "Dist::Zilla::Plugin::PruneCruft" => 0,
    "Dist::Zilla::Plugin::ReadmeAnyFromPod" => "0.120051",
    "Dist::Zilla::Plugin::ReadmeFromPod" => 0,
    "Dist::Zilla::Plugin::ShareDir" => 0,
    "Dist::Zilla::Plugin::TaskWeaver" => "0.101620",
    "Dist::Zilla::Plugin::Test::Compile" => 0,
    "Dist::Zilla::Plugin::Test::Perl::Critic" => 0,
    "Dist::Zilla::Plugin::Test::PodSpelling" => "2.001002",
    "Dist::Zilla::Plugin::Test::Portability" => 0,
    "Dist::Zilla::Plugin::Test::Version" => 0,
    "Dist::Zilla::Plugin::TestRelease" => 0,
    "Dist::Zilla::PluginBundle::Filter" => 0,
    "Dist::Zilla::PluginBundle::Git" => "1.121010",
    "Dist::Zilla::Role::PluginBundle::Config::Slicer" => 0,
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Moose" => "0.99",
    "Pod::Elemental::Transformer::List" => "0.101620",
    "Pod::Weaver::Config::Assembler" => 0,
    "autodie" => "2.00",
    "namespace::autoclean" => "0.09",
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
