# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.010.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Plugin for building Data-Sah distribution",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Dist-Zilla-Plugin-For-Data-Sah",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "Dist::Zilla::Plugin::For::Data::Sah",
  "PREREQ_PM" => {
    "Data::Dump" => 0,
    "Data::Sah::Normalize" => 0,
    "Dist::Zilla::Role::FileFinderUser" => 0,
    "Dist::Zilla::Role::FileMunger" => 0,
    "Moose" => 0,
    "Package::Stash" => 0,
    "Text::Diff" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dump" => 0,
  "Data::Sah::Normalize" => 0,
  "Dist::Zilla::Role::FileFinderUser" => 0,
  "Dist::Zilla::Role::FileMunger" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Moose" => 0,
  "Package::Stash" => 0,
  "Test::More" => 0,
  "Text::Diff" => 0,
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
