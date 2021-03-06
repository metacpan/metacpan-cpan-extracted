# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.014.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Add prerequisites from Rinci metadata",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Dist-Zilla-Plugin-Rinci-AddPrereqs",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "Dist::Zilla::Plugin::Rinci::AddPrereqs",
  "PREREQ_PM" => {
    "Data::Sah" => "0.907",
    "Dist::Zilla::Role::DumpPerinciCmdLineScript" => 0,
    "Dist::Zilla::Role::FileFinderUser" => 0,
    "Dist::Zilla::Role::FileMunger" => 0,
    "Moose" => 0,
    "PMVersions::Util" => 0,
    "Perinci::Access" => 0,
    "Perinci::Sub::Normalize" => "0.19",
    "Perinci::Sub::Util::DepModule" => 0,
    "Perinci::Sub::Util::PropertyModule" => 0,
    "Version::Util" => "0.731",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.145",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Sah" => "0.907",
  "Dist::Zilla::Role::DumpPerinciCmdLineScript" => 0,
  "Dist::Zilla::Role::FileFinderUser" => 0,
  "Dist::Zilla::Role::FileMunger" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Moose" => 0,
  "PMVersions::Util" => 0,
  "Perinci::Access" => 0,
  "Perinci::Sub::Normalize" => "0.19",
  "Perinci::Sub::Util::DepModule" => 0,
  "Perinci::Sub::Util::PropertyModule" => 0,
  "Test::More" => 0,
  "Version::Util" => "0.731",
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
