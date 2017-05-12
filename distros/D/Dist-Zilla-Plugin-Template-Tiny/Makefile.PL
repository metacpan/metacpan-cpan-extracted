
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "process template files in your dist using Template::Tiny",
  "AUTHOR" => "Graham Ollis <plicease\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-Template-Tiny",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::Plugin::Template::Tiny",
  "PREREQ_PM" => {
    "Dist::Zilla::File::InMemory" => 0,
    "Dist::Zilla::Role::FileGatherer" => 0,
    "Dist::Zilla::Role::FileInjector" => 0,
    "Dist::Zilla::Role::FileMunger" => 0,
    "Dist::Zilla::Role::FilePruner" => 0,
    "List::Util" => 0,
    "Moose" => 0,
    "Template::Tiny" => 0,
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "Test::DZil" => 0,
    "Test::More" => "0.88"
  },
  "VERSION" => "0.04",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Dist::Zilla::File::InMemory" => 0,
  "Dist::Zilla::Role::FileGatherer" => 0,
  "Dist::Zilla::Role::FileInjector" => 0,
  "Dist::Zilla::Role::FileMunger" => 0,
  "Dist::Zilla::Role::FilePruner" => 0,
  "List::Util" => 0,
  "Moose" => 0,
  "Template::Tiny" => 0,
  "Test::DZil" => 0,
  "Test::More" => "0.88",
  "namespace::autoclean" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



