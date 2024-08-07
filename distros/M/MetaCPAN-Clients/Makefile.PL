# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.017.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A set of scripts to access MetaCPAN.org via its API and provide reports",
  "AUTHOR" => "Gabor Szabo <szabgab\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "MetaCPAN-Clients",
  "EXE_FILES" => [
    "bin/metacpan_by_author.pl",
    "bin/metacpan_dependency_tree.pl",
    "bin/metacpan_favorite.pl",
    "bin/metacpan_full_dependency_list.pl",
    "bin/metacpan_impact.pl",
    "bin/metacpan_meta.pl",
    "bin/metacpan_namespace.pl",
    "bin/metacpan_old.pl",
    "bin/metacpan_reverse_dependencies.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "MetaCPAN::Clients",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Getopt::Long" => 0,
    "JSON" => 0,
    "MetaCPAN::API" => "0.43",
    "MetaCPAN::Client" => "2.028000",
    "Path::Tiny" => "0.015"
  },
  "VERSION" => "1.00",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dumper" => 0,
  "Getopt::Long" => 0,
  "JSON" => 0,
  "MetaCPAN::API" => "0.43",
  "MetaCPAN::Client" => "2.028000",
  "Path::Tiny" => "0.015"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
