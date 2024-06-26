#
# This file is part of Dist-Zilla-PluginBundle-Git-CheckFor
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.008.
use strict;
use warnings;

# inserted by Dist::Zilla::Plugin::CheckBin 0.007
use Devel::CheckBin;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "All Git::CheckFor plugins at once",
  "AUTHOR" => "Chris Weyl <cweyl\@alumni.drew.edu>",
  "CONFIGURE_REQUIRES" => {
    "Devel::CheckBin" => 0,
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-Git-CheckFor",
  "LICENSE" => "lgpl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Dist::Zilla::PluginBundle::Git::CheckFor",
  "PREREQ_PM" => {
    "Dist::Zilla::Plugin::Git::NextVersion" => "1.120370",
    "Dist::Zilla::Role::BeforeRelease" => 0,
    "Dist::Zilla::Role::Git::Repo" => 0,
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Git::Wrapper" => 0,
    "IPC::System::Simple" => 0,
    "List::Util" => "1.33",
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::AttributeShortcuts" => 0,
    "Try::Tiny" => 0,
    "autodie" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::chdir" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Path::Tiny" => 0,
    "Test::CheckDeps" => "0.010",
    "Test::DZil" => 0,
    "Test::Fatal" => 0,
    "Test::Moose::More" => "0.008",
    "Test::More" => "0.94",
    "Test::TempDir::Tiny" => 0,
    "blib" => "1.01"
  },
  "VERSION" => "0.014",
  "test" => {
    "TESTS" => "t/*.t t/plugin/*.t"
  }
);


my %FallbackPrereqs = (
  "Capture::Tiny" => 0,
  "Dist::Zilla::Plugin::Git::NextVersion" => "1.120370",
  "Dist::Zilla::Role::BeforeRelease" => 0,
  "Dist::Zilla::Role::Git::Repo" => 0,
  "Dist::Zilla::Role::PluginBundle::Easy" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::chdir" => 0,
  "Git::Wrapper" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "IPC::System::Simple" => 0,
  "List::Util" => "1.33",
  "Moose" => 0,
  "Moose::Role" => 0,
  "MooseX::AttributeShortcuts" => 0,
  "Path::Tiny" => 0,
  "Test::CheckDeps" => "0.010",
  "Test::DZil" => 0,
  "Test::Fatal" => 0,
  "Test::Moose::More" => "0.008",
  "Test::More" => "0.94",
  "Test::TempDir::Tiny" => 0,
  "Try::Tiny" => 0,
  "autodie" => 0,
  "blib" => "1.01",
  "namespace::autoclean" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
