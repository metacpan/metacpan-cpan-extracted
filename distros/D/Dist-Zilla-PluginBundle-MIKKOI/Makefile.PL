# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.030.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "BeLike::MIKKOI when you build your dists",
  "AUTHOR" => "Mikko Koivunalho <mikkoi\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-MIKKOI",
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::PluginBundle::MIKKOI",
  "PREREQ_PM" => {
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Moose" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Carp" => 0,
    "English" => 0,
    "File::Find" => 0,
    "File::Spec" => 0,
    "FindBin" => "1.51",
    "Module::Load" => 0,
    "Test2::V0" => 0,
    "lib" => 0,
    "utf8" => 0
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Dist::Zilla::Role::PluginBundle::Easy" => 0,
  "English" => 0,
  "File::Find" => 0,
  "File::Spec" => 0,
  "FindBin" => "1.51",
  "Module::Load" => 0,
  "Moose" => 0,
  "Test2::V0" => 0,
  "lib" => 0,
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
