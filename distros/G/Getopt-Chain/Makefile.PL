
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Command-line processing like svn and git',
  'AUTHOR' => 'Robert Krimen <robertkrimen@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::Most' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Getopt-Chain',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Getopt::Chain',
  'PREREQ_PM' => {
    'Carp::Clan::Share' => '0',
    'Getopt::Long' => '2.37',
    'Hash::Param' => '0',
    'Moose' => '0',
    'MooseX::AttributeHelpers' => '0',
    'MooseX::MakeImmutable' => '0.02',
    'Path::Dispatcher' => '0',
    'Path::Dispatcher::Declarative' => '0'
  },
  'VERSION' => '0.017',
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



