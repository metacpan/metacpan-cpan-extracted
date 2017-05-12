
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Manage a set of DBI handles',
  'AUTHOR' => 'Dave Rolsky <autarch@urth.org>',
  'BUILD_REQUIRES' => {
    'DBD::Mock' => '1.38',
    'DBI' => '0',
    'Fey::Test' => '0.08',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Fey-DBIManager',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'Fey::DBIManager',
  'PREREQ_PM' => {
    'Fey' => '0.12',
    'Moose' => '0.90',
    'MooseX::SemiAffordanceAccessor' => '0.05',
    'MooseX::StrictConstructor' => '0.08',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.16',
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



