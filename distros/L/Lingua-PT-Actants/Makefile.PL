# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.008.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "compute verb actants for Portuguese",
  "AUTHOR" => "Nuno Carvalho <smash\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Lingua-PT-Actants",
  "EXE_FILES" => [
    "bin/actants",
    "bin/drop-auxs"
  ],
  "LICENSE" => "perl",
  "NAME" => "Lingua::PT::Actants",
  "PREREQ_PM" => {
    "Path::Tiny" => 0,
    "Storable" => 0,
    "lib" => 0,
    "strict" => 0,
    "utf8::all" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0,
    "utf8" => 0
  },
  "VERSION" => "0.05",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Path::Tiny" => 0,
  "Storable" => 0,
  "Test::More" => 0,
  "lib" => 0,
  "strict" => 0,
  "utf8" => 0,
  "utf8::all" => 0,
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
