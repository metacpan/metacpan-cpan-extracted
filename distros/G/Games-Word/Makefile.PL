
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "utility functions for writing word games",
  "AUTHOR" => "Jesse Luehrs <doy at tozt dot net>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::Deep" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Games-Word",
  "EXE_FILES" => [
    "bin/solve-xghost.pl",
    "bin/mastermind.pl",
    "bin/solve-spook.pl",
    "bin/cryptogram.pl",
    "bin/jotto.pl",
    "bin/solve-ghost.pl",
    "bin/solve-superghost.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Games::Word",
  "PREREQ_PM" => {
    "Exporter" => 0,
    "List::MoreUtils" => 0,
    "Math::Combinatorics" => 0,
    "Test::Deep::NoTest" => 0,
    "base" => 0,
    "integer" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.06",
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



