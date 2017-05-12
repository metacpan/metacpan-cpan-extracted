use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
    NAME                => 'FSA::Engine',
    VERSION_FROM        => 'lib/FSA/Engine.pm',
    AUTHOR              => 'Ian Docherty <pause@iandocherty.com>',
    BUILD_REQUIRES      => {
        'ExtUtils::MakeMaker'   => '6.42',
        'Test::More'            => '0.88',
        'Test::Output'          => '0',
        'FindBin::libs'         => '0',
    },
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker'   => '6.30',
    },
    DISTNAME            => 'FSA-Engine',
    EXE_FILES           => [],
    LICENSE             => 'perl',
    PREREQ_PM           => {
        'Moose'                 => '1.10',
        'Moose::Role'           => '0',
    },
    test                => {
        TESTS                   =>  't/*.t',
    },
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
