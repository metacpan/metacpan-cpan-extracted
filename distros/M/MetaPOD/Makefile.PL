# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.009.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "An evolution of POD",
  "AUTHOR" => "Kent Fredric <kentnl\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "MetaPOD",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "MetaPOD",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dump" => 0,
    "List::AllUtils" => 0,
    "Module::Runtime" => 0,
    "Moo" => "1.000008",
    "Moo::Role" => 0,
    "Pod::Eventual" => 0,
    "Throwable::Error" => 0,
    "strict" => 0,
    "version" => "0.77",
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "Path::Iterator::Rule" => 0,
    "Path::Tiny" => 0,
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "Test::Needs" => 0
  },
  "VERSION" => "v0.4.0",
  "test" => {
    "TESTS" => "t/*.t t/00-compile/*.t t/01-extractor/*.t t/02-role-formatter/*.t t/03-result/*.t t/04-assembler/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Dump" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "FindBin" => 0,
  "List::AllUtils" => 0,
  "Module::Runtime" => 0,
  "Moo" => "1.000008",
  "Moo::Role" => 0,
  "Path::Iterator::Rule" => 0,
  "Path::Tiny" => 0,
  "Pod::Eventual" => 0,
  "Test::Fatal" => 0,
  "Test::More" => 0,
  "Test::Needs" => 0,
  "Throwable::Error" => 0,
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
