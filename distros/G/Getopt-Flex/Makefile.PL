
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Option parsing, done differently',
  'AUTHOR' => 'Ryan P. Kelly <rpkelly@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::Exception' => '0',
    'Test::More' => '0',
    'Test::Output' => '0',
    'Test::Warn' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Getopt-Flex',
  'EXE_FILES' => [],
  'LICENSE' => 'mit',
  'NAME' => 'Getopt::Flex',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Clone' => '0',
    'Hash::Merge' => '0',
    'Moose' => '0',
    'Moose::Meta::TypeConstraint' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::StrictConstructor' => '0'
  },
  'VERSION' => '1.07',
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



