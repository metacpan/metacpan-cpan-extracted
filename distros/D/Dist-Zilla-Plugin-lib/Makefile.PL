# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.009.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A simpler bootstrap for a more civilised world",
  "AUTHOR" => "Kent Fredric <kentnl\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Dist-Zilla-Plugin-lib",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Dist::Zilla::Plugin::lib",
  "PREREQ_PM" => {
    "Dist::Zilla::Role::Plugin" => 0,
    "Moose" => 0,
    "MooseX::Types::Moose" => 0,
    "Path::Tiny" => 0,
    "lib" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::DZil" => 0,
    "Test::More" => 0,
    "constant" => 0
  },
  "VERSION" => "0.001002",
  "test" => {
    "TESTS" => "t/*.t t/00-compile/*.t"
  }
);


my %FallbackPrereqs = (
  "Dist::Zilla::Role::Plugin" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Moose" => 0,
  "MooseX::Types::Moose" => 0,
  "Path::Tiny" => 0,
  "Test::DZil" => 0,
  "Test::More" => 0,
  "constant" => 0,
  "lib" => 0,
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
