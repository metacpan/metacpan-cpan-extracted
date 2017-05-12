
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A declarative approach to HTML generation",
  "AUTHOR" => "Chris Weyl <cweyl\@alumni.drew.edu>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTML-Builder",
  "EXE_FILES" => [],
  "LICENSE" => "lgpl",
  "NAME" => "HTML::Builder",
  "PREREQ_PM" => {
    "Capture::Tiny" => "0.15",
    "HTML::Tiny" => 0,
    "List::MoreUtils" => 0,
    "Sub::Exporter" => 0,
    "Sub::Install" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.008",
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



