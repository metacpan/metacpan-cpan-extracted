
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Tiger/LINE feature abbreviations',
  'AUTHOR' => 'Josh Jore <jjore@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Geo-TigerLine-Abbreviations',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Geo::TigerLine::Abbreviations',
  'PREREQ_PM' => {
    'Cache::Cache' => '0',
    'LWP::Simple' => '0'
  },
  'VERSION' => '0.04',
  'test' => {
    'TESTS' => ''
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



