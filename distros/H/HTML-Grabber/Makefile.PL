
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "jQuery style DOM traversal/manipulation",
  "AUTHOR" => "Martyn Smith <martyn\@dollyfish.net.nz>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTML-Grabber",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "HTML::Grabber",
  "PREREQ_PM" => {
    "HTML::Selector::XPath" => "0.03",
    "Moose" => "0.94",
    "XML::LibXML" => "1.70"
  },
  "VERSION" => "0.7",
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



