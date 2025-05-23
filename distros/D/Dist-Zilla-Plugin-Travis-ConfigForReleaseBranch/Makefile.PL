#
# This file is part of Dist-Zilla-Plugin-Travis-ConfigForReleaseBranch
#
# This software is Copyright (c) 2017, 2015, 2013 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.009.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Create a C<.travis.yml> suitable for built branches",
  "AUTHOR" => "Chris Weyl <cweyl\@alumni.drew.edu>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Dist-Zilla-Plugin-Travis-ConfigForReleaseBranch",
  "LICENSE" => "lgpl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Dist::Zilla::Plugin::Travis::ConfigForReleaseBranch",
  "PREREQ_PM" => {
    "Dist::Zilla::Plugin::InlineFiles" => 0,
    "Moose" => 0,
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::CheckDeps" => "0.010",
    "Test::More" => "0.94",
    "blib" => "1.01",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.005",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Dist::Zilla::Plugin::InlineFiles" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Moose" => 0,
  "Test::CheckDeps" => "0.010",
  "Test::More" => "0.94",
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
