# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.005.
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Release tests for checking changes",
  "AUTHOR" => "Marcel Gr\x{fc}nauer <marcel\@cpan.org>, Mike Doherty <doherty\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Dist-Zilla-Plugin-Test-CheckChanges",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008",
  "NAME" => "Dist::Zilla::Plugin::Test::CheckChanges",
  "PREREQ_PM" => {
    "Dist::Zilla::Plugin::InlineFiles" => 0,
    "Moose" => 0,
    "Test::CheckChanges" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "version" => "0.77",
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::DZil" => 0,
    "Test::More" => "0.96",
    "Test::Output" => 0,
    "autodie" => 0,
    "blib" => "1.01"
  },
  "VERSION" => "2.000004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Dist::Zilla::Plugin::InlineFiles" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Moose" => 0,
  "Test::CheckChanges" => 0,
  "Test::DZil" => 0,
  "Test::More" => "0.96",
  "Test::Output" => 0,
  "autodie" => 0,
  "blib" => "1.01",
  "namespace::autoclean" => 0,
  "strict" => 0,
  "version" => "0.77",
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
