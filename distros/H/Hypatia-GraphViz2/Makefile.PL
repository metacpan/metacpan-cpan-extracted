
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Hypatia Bindings for GraphViz2",
  "AUTHOR" => "Jack Maney <jack\@jackmaney.com>",
  "BUILD_REQUIRES" => {
    "Hypatia" => 0,
    "Hypatia::DBI::Test::SQLite" => 0,
    "Scalar::Util" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Hypatia-GraphViz2",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Hypatia::GraphViz2",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "GraphViz2" => "2.05",
    "Hypatia" => "0.027",
    "Hypatia::Base" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Aliases" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.015",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



