# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.014000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "match contents of a hash against rules",
  "AUTHOR" => "Robert Rothenberg <rrwo\@cpan.org>",
  "BUILD_REQUIRES" => {
    "ExtUtils::MakeMaker" => "7.22",
    "Module::Metadata" => "1.000015"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Hash-Match",
  "LICENSE" => "artistic_2",
  "MIN_PERL_VERSION" => "5.014000",
  "NAME" => "Hash::Match",
  "PREREQ_PM" => {
    "Carp" => 0,
    "List::AllUtils" => 0,
    "Ref::Util" => 0,
    "namespace::autoclean" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "Module::Metadata" => "1.000015",
    "Test::Exception" => 0,
    "Test::More" => "0.98",
    "if" => 0,
    "strict" => 0
  },
  "VERSION" => "v0.8.2",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "ExtUtils::MakeMaker" => "7.22",
  "File::Spec" => 0,
  "List::AllUtils" => 0,
  "Module::Metadata" => "1.000015",
  "Ref::Util" => 0,
  "Test::Exception" => 0,
  "Test::More" => "0.98",
  "if" => 0,
  "namespace::autoclean" => 0,
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
