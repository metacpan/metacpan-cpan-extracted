#!perl

use 5.006;
use strict;
use warnings;

# Automatically generated file; DO NOT EDIT.

use Test::More 0.88;

use lib qw(lib);

my @modules = qw(
  Dist::Zilla::Plugin::Code
  Dist::Zilla::Plugin::Code::AfterBuild
  Dist::Zilla::Plugin::Code::AfterRelease
  Dist::Zilla::Plugin::Code::BeforeArchive
  Dist::Zilla::Plugin::Code::BeforeBuild
  Dist::Zilla::Plugin::Code::BeforeRelease
  Dist::Zilla::Plugin::Code::BuildRunner
  Dist::Zilla::Plugin::Code::EncodingProvider
  Dist::Zilla::Plugin::Code::FileFinder
  Dist::Zilla::Plugin::Code::FileGatherer
  Dist::Zilla::Plugin::Code::FileMunger
  Dist::Zilla::Plugin::Code::FilePruner
  Dist::Zilla::Plugin::Code::InstallTool
  Dist::Zilla::Plugin::Code::LicenseProvider
  Dist::Zilla::Plugin::Code::MetaProvider
  Dist::Zilla::Plugin::Code::NameProvider
  Dist::Zilla::Plugin::Code::PrereqSource
  Dist::Zilla::Plugin::Code::ReleaseStatusProvider
  Dist::Zilla::Plugin::Code::Releaser
  Dist::Zilla::Plugin::Code::TestRunner
  Dist::Zilla::Plugin::Code::VersionProvider
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}
