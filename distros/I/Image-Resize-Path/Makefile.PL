
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A lightweight wrapper to GD for mass image resizing',
  'AUTHOR' => 'Logan Bell <logan@orchardtech.com>',
  'BUILD_REQUIRES' => {
    'Cwd' => '0',
    'Data::Dumper' => '0',
    'Test::MockObject' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Image-Resize-Path',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Image::Resize::Path',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::Accessor' => '0',
    'GD' => '0',
    'GD::Image' => '0'
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



