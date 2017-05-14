
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Sugar for class-based exception handlers',
  'AUTHOR' => 'Paul Driver <frodwith@cpan.org>',
  'BUILD_REQUIRES' => {
    'Exception::Class' => '0',
    'Test::More' => '0',
    'Try::Tiny' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Exception-Caught',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Exception::Caught',
  'PREREQ_PM' => {
    'Scalar::Util' => '0',
    'Sub::Exporter' => '0',
    'Sub::Exporter::Lexical' => '0',
    'namespace::clean' => '0'
  },
  'VERSION' => '0.01',
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



