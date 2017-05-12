
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Dist::Zilla plugin for Test::Kwalitee::Extra",
  "AUTHOR" => "Yasutaka ATARASHI <yakex\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-Test-Kwalitee-Extra",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::Plugin::Test::Kwalitee::Extra",
  "PREREQ_PM" => {
    "Data::Section" => 0,
    "Dist::Zilla" => 0,
    "File::Path" => "2.08",
    "Module::CPANTS::Analyse" => "0.87",
    "Moose" => 0,
    "Test::Kwalitee::Extra" => "v0.2.1",
    "Test::More" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Path::Class" => 0,
    "Test::More" => 0,
    "version" => "0.77"
  },
  "VERSION" => "v0.2.1",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Capture::Tiny" => 0,
  "Data::Section" => 0,
  "Dist::Zilla" => 0,
  "File::Path" => "2.08",
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::CPANTS::Analyse" => "0.87",
  "Moose" => 0,
  "Path::Class" => 0,
  "Test::Kwalitee::Extra" => "v0.2.1",
  "Test::More" => 0,
  "version" => "0.77"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



