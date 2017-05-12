
use strict;
use warnings;



use ExtUtils::MakeMaker;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Two letter codes for state identification in the United States and vice versa.',
  'AUTHOR' => 'Mike Accardo',
  'BUILD_REQUIRES' => {
    'Test' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '0'
  },
  'DISTNAME' => 'Locale-US',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Locale::US',
  'PREREQ_PM' => {
    'Data::Dumper' => '0',
    'Data::Section::Simple' => '0'
  },
  'VERSION' => '3.04',
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
