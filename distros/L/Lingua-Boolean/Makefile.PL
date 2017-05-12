
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "DEPRECATED module to comprehensively parse boolean response strings",
  "AUTHOR" => "Mike Doherty <doherty\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Lingua-Boolean",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Lingua::Boolean",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Exporter" => 0,
    "Module::Load" => 0,
    "String::Trim" => 0,
    "boolean" => "0.21",
    "experimental" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Builder" => "0.94",
    "Test::More" => "0.94"
  },
  "VERSION" => "0.008",
  "test" => {
    "TESTS" => "t/*.t t/lang/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Exporter" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.3601",
  "Module::Load" => 0,
  "String::Trim" => 0,
  "Test::Builder" => "0.94",
  "Test::More" => "0.94",
  "boolean" => "0.21",
  "experimental" => 0,
  "strict" => 0,
  "utf8" => 0,
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



