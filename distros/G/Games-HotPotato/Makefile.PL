
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'a simple game timer for hot potato or whatever',
  'AUTHOR' => 'Andrew Sterling Hanenkamp <hanenkamp@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Games-HotPotato',
  'EXE_FILES' => [
    'bin/hot-potato',
    'bin/hot-potato'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Games::HotPotato',
  'PREREQ_PM' => {
    'Config::INI::Reader' => '0',
    'DateTime::Duration' => '0',
    'Getopt::Long' => '0',
    'Moose' => '0',
    'MooseX::Types::DateTime' => '0',
    'MooseX::Types::Path::Class' => '0',
    'Path::Class' => '0',
    'SDL::Mixer' => '0',
    'SDL::Mixer::Music' => '0'
  },
  'VERSION' => '0.110020',
  'test' => {
    'TESTS' => 't/*.t'
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



