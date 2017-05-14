
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "communication module for debuging processes",
  "AUTHOR" => "Jean-Christian HASSLER <hasslerjeanchristian at gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Devel-Debug-Server",
  "EXE_FILES" => [
    "bin/debugAgent.pl",
    "bin/debugServer.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Devel::Debug::Server",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Devel::ebug" => 0,
    "File::Spec" => 0,
    "JSON" => 0,
    "Storable" => 0,
    "Time::HiRes" => 0,
    "ZeroMQ" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Class::Accessor::Chained::Fast" => 0,
    "FindBin" => 0,
    "Proc::Background" => 0,
    "Test::More" => 0,
    "base" => 0,
    "lib" => 0
  },
  "VERSION" => "1.001",
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



