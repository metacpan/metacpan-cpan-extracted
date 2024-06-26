# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;



use ExtUtils::MakeMaker 7.1101;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Check for Redis connectivity and operations in HealthCheck",
  "AUTHOR" => "Grant Street Group <developers\@grantstreet.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "7.1101"
  },
  "DISTNAME" => "HealthCheck-Diagnostic-Redis",
  "LICENSE" => "artistic_2",
  "NAME" => "HealthCheck::Diagnostic::Redis",
  "PREREQ_PM" => {
    "Carp" => 0,
    "HealthCheck::Diagnostic" => 0,
    "Redis::Fast" => 0,
    "String::Random" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Differences" => 0,
    "Test::MockModule" => 0,
    "Test::More" => 0
  },
  "VERSION" => "v0.0.6",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Dumper" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "HealthCheck::Diagnostic" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Redis::Fast" => 0,
  "String::Random" => 0,
  "Test::Differences" => 0,
  "Test::MockModule" => 0,
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
