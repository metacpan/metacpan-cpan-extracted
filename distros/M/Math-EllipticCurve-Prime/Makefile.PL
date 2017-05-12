
use strict;
use warnings;

use 5.006002;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "elliptic curve operations over prime fields",
  "AUTHOR" => "brian m. carlson <sandals\@crustytoothpaste.net>",
  "BUILD_REQUIRES" => {
    "FindBin" => 0,
    "Test::More" => 0,
    "Test::NoWarnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Math-EllipticCurve-Prime",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Math::EllipticCurve::Prime",
  "PREREQ_PM" => {
    "List::Util" => 0,
    "Math::BigInt" => "1.78",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.003",
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



