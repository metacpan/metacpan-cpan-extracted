
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl extension to simulate rolling loaded dice",
  "AUTHOR" => "Miles Gould <miles\@assyrian.org.uk>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Games-Dice-Loaded",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Games::Dice::Loaded",
  "PREREQ_PM" => {
    "AutoLoader" => 0,
    "Carp" => 0,
    "Exporter" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Moose" => "2.0300",
    "Statistics::Distributions" => "1.02",
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.002",
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



