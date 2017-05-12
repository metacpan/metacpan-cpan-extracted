
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Interface to the mypeople service for p5-hubot",
  "AUTHOR" => "Hyungsuk Hong <hshong\@perl.kr>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Hubot-Adapter-Mypeople",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Hubot::Adapter::Mypeople",
  "PREREQ_PM" => {
    "AnyEvent::MyPeopleBot::Client" => 0,
    "Encode" => 0,
    "Hubot::Adapter" => 0,
    "Hubot::Message" => 0,
    "JSON::XS" => 0,
    "Moose" => 0,
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0,
    "strict" => 0
  },
  "VERSION" => "0.0.6",
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



