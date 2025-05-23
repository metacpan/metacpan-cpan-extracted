# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.024.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Log output via Twilio SMS Message",
  "AUTHOR" => "Graham TerMarsch <cpan\@howlingfrog.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Log-Dispatch-Twilio",
  "LICENSE" => "artistic_2",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "Log::Dispatch::Twilio",
  "PREREQ_PM" => {
    "HTTP::Status" => 0,
    "Log::Dispatch" => 0,
    "WWW::Twilio::API" => 0,
    "namespace::clean" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Sub::Override" => 0,
    "Test::DiagINC" => "0.002",
    "Test::More" => "0.96"
  },
  "VERSION" => "0.04",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::Temp" => 0,
  "HTTP::Status" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Log::Dispatch" => 0,
  "Sub::Override" => 0,
  "Test::DiagINC" => "0.002",
  "Test::More" => "0.96",
  "WWW::Twilio::API" => 0,
  "namespace::clean" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
