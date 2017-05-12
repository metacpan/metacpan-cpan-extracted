
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A Form::Sensible::Reflector subclass to reflect off of DBIC schema classes',
  'AUTHOR' => 'Devin Austin <dhoss@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Form-Sensible-Reflector-DBIC',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Form::Sensible::Reflector::DBIC',
  'PREREQ_PM' => {
    'DBIx::Class' => '0',
    'Data::Dumper' => '0',
    'DateTime' => '0',
    'Form::Sensible' => '0.20012',
    'Moose' => '0.93',
    'SQL::Translator' => '0.11002',
    'Test::Simple' => '0.88'
  },
  'VERSION' => '0.349',
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



