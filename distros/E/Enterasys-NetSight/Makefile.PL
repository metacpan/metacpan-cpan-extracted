
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Provides an abstraction layer between SOAP::Lite and the Netsight Device WebService.",
  "AUTHOR" => "Chris Handwerker <chandwer\@enterasys.com>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Enterasys-NetSight",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Enterasys::NetSight",
  "PREREQ_PM" => {
    "Carp" => 0,
    "SOAP::Lite" => 0,
    "Socket" => 0
  },
  "VERSION" => "1.2",
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



