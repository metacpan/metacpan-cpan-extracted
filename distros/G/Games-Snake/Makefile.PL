
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Snake game",
  "AUTHOR" => "Jeffrey T. Palmer <jtpalmer\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Games-Snake",
  "EXE_FILES" => [
    "bin/snake.pl"
  ],
  "LICENSE" => "mit",
  "NAME" => "Games::Snake",
  "PREREQ_PM" => {
    "Moo" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "SDL" => "2.500",
    "SDL::Event" => 0,
    "SDLx::App" => 0,
    "Sub::Quote" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.000001",
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



