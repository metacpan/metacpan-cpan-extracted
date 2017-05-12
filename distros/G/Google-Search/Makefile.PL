
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Interface to the Google AJAX Search API and suggestion API (DEPRECATED)",
  "AUTHOR" => "Robert Krimen <robertkrimen\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::Most" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Google-Search",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Google::Search",
  "PREREQ_PM" => {
    "Any::Moose" => 0,
    "Carp::Clan::Share" => 0,
    "JSON" => 2,
    "LWP::UserAgent" => 0,
    "Try::Tiny" => 0,
    "URI" => 0
  },
  "VERSION" => "0.028",
  "test" => {
    "TESTS" => "t/*.t t/9bug/*.t"
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



