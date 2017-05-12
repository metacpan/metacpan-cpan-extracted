
use strict;
use warnings;

use 5.012;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A Perl library client for the EVE Central API.",
  "AUTHOR" => "Pedro Figueiredo <me\@pedrofigueiredo.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Games-EveOnline-EveCentral",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Games::EveOnline::EveCentral",
  "PREREQ_PM" => {
    "HTTP::Headers" => "6.05",
    "HTTP::Request" => "6.0",
    "JSON" => "2.90",
    "LWP::UserAgent::Determined" => "1.06",
    "Moo" => "1.003001",
    "MooX::StrictConstructor" => "0.006",
    "MooX::Types::MooseLike" => "0.25",
    "MooX::Types::MooseLike::Base" => 0,
    "Readonly" => "1.03",
    "Sub::Quote" => "1.003001",
    "Try::Tiny" => "0.18",
    "URI::Escape" => "3.31",
    "XML::LibXML" => "2.0108"
  },
  "TEST_REQUIRES" => {
    "Encode" => 0,
    "Error" => 0,
    "Exporter" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "HTTP::Response" => 0,
    "Test::Exception" => 0,
    "Test::Mock::Class" => "0.0303",
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.001",
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



