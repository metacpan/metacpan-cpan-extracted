
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A Data Visualization API",
  "AUTHOR" => "Jack Maney <jack\@jackmaney.com>",
  "BUILD_REQUIRES" => {
    "Cwd" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Hypatia",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Hypatia",
  "PREREQ_PM" => {
    "Array::Utils" => 0,
    "Class::Load" => 0,
    "DBI" => 0,
    "Data::Dumper" => 0,
    "JSON" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "Path::Class" => 0,
    "Scalar::Util" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.029",
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



