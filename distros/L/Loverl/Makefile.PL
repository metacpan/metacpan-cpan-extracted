# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.030.
use strict;
use warnings;

use 5.036000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A L\x{d6}VE2D game development command-line interface.",
  "AUTHOR" => "Nobunaga <nobunaga\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Loverl",
  "EXE_FILES" => [
    "bin/loverl"
  ],
  "LICENSE" => "mit",
  "MIN_PERL_VERSION" => "5.036000",
  "NAME" => "Loverl",
  "PREREQ_PM" => {
    "App::Cmd::Setup" => 0,
    "Archive::Zip" => 0,
    "Carp" => 0,
    "Cwd" => 0,
    "FindBin" => 0,
    "Git::Repository" => 0,
    "Moose" => 0,
    "constant" => 0,
    "lib" => 0
  },
  "TEST_REQUIRES" => {
    "App::Cmd::Tester" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.005",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "App::Cmd::Setup" => 0,
  "App::Cmd::Tester" => 0,
  "Archive::Zip" => 0,
  "Carp" => 0,
  "Cwd" => 0,
  "FindBin" => 0,
  "Git::Repository" => 0,
  "Moose" => 0,
  "Test::More" => 0,
  "constant" => 0,
  "lib" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
