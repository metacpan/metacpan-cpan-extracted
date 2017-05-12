
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Calculate Distances and Closest Locations",
  "AUTHOR" => "Aran Deltac <bluefeet\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::Fatal" => "0.007",
    "Test::Simple" => "0.94"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Geo-Distance",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Geo::Distance",
  "PREREQ_PM" => {
    "Math::Complex" => 0
  },
  "VERSION" => "0.20",
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



