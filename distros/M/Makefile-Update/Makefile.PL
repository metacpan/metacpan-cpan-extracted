# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.010.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Update make files.",
  "AUTHOR" => "Vadim Zeitlin <vz-cpan\@zeitlins.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Makefile-Update",
  "EXE_FILES" => [
    "bin/upmake"
  ],
  "LICENSE" => "perl",
  "NAME" => "Makefile::Update",
  "PREREQ_PM" => {},
  "TEST_REQUIRES" => {
    "Test::LongString" => 0,
    "Test::More" => 0,
    "Test::Output" => 0,
    "Test::Warn" => 0
  },
  "VERSION" => "0.4",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Test::LongString" => 0,
  "Test::More" => 0,
  "Test::Output" => 0,
  "Test::Warn" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
