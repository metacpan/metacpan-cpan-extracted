
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "HTTP Action, Adventure and Excitement",
  "AUTHOR" => "Stevan Little <stevan.little\@iinteractive.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTTP-Headers-ActionPack",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "HTTP::Headers::ActionPack",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Encode" => 0,
    "HTTP::Date" => 0,
    "HTTP::Headers::Util" => 0,
    "List::Util" => 0,
    "MIME::Base64" => 0,
    "Module::Runtime" => 0,
    "Scalar::Util" => 0,
    "Sub::Exporter" => 0,
    "Time::Piece" => 0,
    "URI::Escape" => 0,
    "overload" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "HTTP::Headers" => 0,
    "HTTP::Request" => 0,
    "HTTP::Response" => 0,
    "Test::Fatal" => "0.0003",
    "Test::More" => "0.88",
    "Test::Warnings" => 0
  },
  "VERSION" => "0.09",
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



