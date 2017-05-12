
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Plugin configuration containing settings for a Git repo",
  "AUTHOR" => "Brendan Byrd <BBYRD\@CPAN.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {},
  "DISTNAME" => "Dist-Zilla-Plugin-Config-Git",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Dist::Zilla::Plugin::Config::Git",
  "PREREQ_PM" => {
    "Dist::Zilla::Role::Plugin" => "1.000",
    "Moose" => "0.34",
    "MooseX::Types" => "0.06",
    "String::Errf" => "0.001",
    "namespace::clean" => "0.06"
  },
  "TEST_REQUIRES" => {
    "Test::CheckDeps" => "0.010",
    "Test::More" => "0.94"
  },
  "VERSION" => "0.92",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Dist::Zilla::Role::Plugin" => "1.000",
  "Moose" => "0.34",
  "MooseX::Types" => "0.06",
  "String::Errf" => "0.001",
  "Test::CheckDeps" => "0.010",
  "Test::More" => "0.94",
  "namespace::clean" => "0.06"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



