
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Generate SQL with PostgreSQL specific extensions',
  'AUTHOR' => 'Oliver Charles <oliver.g.charles@googlemail.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Fey-SQL-Pg',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Fey::SQL::Pg',
  'PREREQ_PM' => {
    'Fey::SQL' => '0.34',
    'Method::Signatures::Simple' => '0.05',
    'Moose' => '0.90',
    'MooseX::Params::Validate' => '0.13',
    'MooseX::StrictConstructor' => '0.08',
    'namespace::autoclean' => '0.09'
  },
  'VERSION' => '0.005',
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



