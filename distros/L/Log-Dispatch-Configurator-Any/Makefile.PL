
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Configurator implementation with Config::Any',
  'AUTHOR' => 'Oliver Gorwits <oliver@cpan.org>',
  'BUILD_REQUIRES' => {
    'Config::Tiny' => '0',
    'Log::Dispatch::Config' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Log-Dispatch-Configurator-Any',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Log::Dispatch::Configurator::Any',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Config::Any' => '0.15',
    'Log::Dispatch' => '2.23',
    'Log::Dispatch::Configurator' => '0',
    'Sys::Syslog' => '0.25'
  },
  'VERSION' => '1.122640',
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



