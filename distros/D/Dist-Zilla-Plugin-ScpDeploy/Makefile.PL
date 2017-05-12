
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'deploy via scp and ssh',
  'AUTHOR' => 'chromatic',
  'BUILD_REQUIRES' => {
    'Test::DZil' => '0',
    'Test::Fatal' => '0.006',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Dist-Zilla-Plugin-ScpDeploy',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dist::Zilla::Plugin::ScpDeploy',
  'PREREQ_PM' => {
    'Dist::Zilla' => '4.200007',
    'Dist::Zilla::Role::Releaser' => '0',
    'Moose' => '2.0007',
    'Moose::Util::TypeConstraints' => '0',
    'constant' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '1.20110709',
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



