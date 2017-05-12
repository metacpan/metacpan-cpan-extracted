
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Data mapper for Moose classes an objects",
  "AUTHOR" => "Mariano Wahlmann, Gines Razanov",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Gideon",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Gideon",
  "PREREQ_PM" => {
    "DBD::Mock" => 0,
    "DBI" => 0,
    "DateTime" => 0,
    "DateTime::Format::MySQL" => 0,
    "JSON" => 0,
    "Moose" => 0,
    "MooseX::Test::Role" => 0,
    "SQL::Abstract" => 0,
    "SQL::Abstract::Limit" => 0,
    "Test::Class::Moose" => 0,
    "Test::Exception" => 0,
    "Test::MockObject" => 0,
    "Throwable" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.0.3",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



