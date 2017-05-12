
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Load your schema definition from a DBMS",
  "AUTHOR" => "Dave Rolsky <autarch\@urth.org>",
  "BUILD_REQUIRES" => {
    "Fey::Test" => "0.10",
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Fey-Loader",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Fey::Loader",
  "PREREQ_PM" => {
    "DBI" => 0,
    "Fey" => 0,
    "Moose" => 0,
    "MooseX::Params::Validate" => "0.08",
    "Scalar::Util" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.13",
  "test" => {
    "TESTS" => "t/*.t t/Loader/*.t"
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



