# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.031.
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 7.1101;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Verify SSH connectivity to specified host.",
  "AUTHOR" => "Grant Street Group <developers\@grantstreet.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "7.1101"
  },
  "DISTNAME" => "HealthCheck-Diagnostic-SSH",
  "LICENSE" => "artistic_2",
  "MIN_PERL_VERSION" => "5.010000",
  "NAME" => "HealthCheck::Diagnostic::SSH",
  "PREREQ_PM" => {
    "HealthCheck::Diagnostic" => 0,
    "Net::SSH::Perl" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test2::V0" => 0,
    "Test::More" => 0
  },
  "VERSION" => "v0.1.0",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "HealthCheck::Diagnostic" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Net::SSH::Perl" => 0,
  "Test2::V0" => 0,
  "Test::More" => 0,
  "parent" => 0,
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
