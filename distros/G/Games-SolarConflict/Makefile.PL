
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Spacewar! clone",
  "AUTHOR" => "Jeffrey T. Palmer <jtpalmer\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Games-SolarConflict",
  "EXE_FILES" => [
    "bin/solar-conflict.pl"
  ],
  "LICENSE" => "mit",
  "NAME" => "Games::SolarConflict",
  "PREREQ_PM" => {
    "File::ShareDir" => 0,
    "FindBin" => 0,
    "Math::Trig" => 0,
    "Mouse" => 0,
    "Mouse::Role" => 0,
    "Path::Class" => 0,
    "SDL" => "2.532",
    "SDL::Color" => 0,
    "SDL::Event" => 0,
    "SDL::Events" => 0,
    "SDL::GFX::Primitives" => 0,
    "SDL::Rect" => 0,
    "SDLx::App" => 0,
    "SDLx::Controller::Interface" => 0,
    "SDLx::Controller::State" => 0,
    "SDLx::Sprite" => 0,
    "SDLx::Sprite::Animated" => 0,
    "SDLx::Surface" => 0,
    "SDLx::Text" => 0,
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

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


