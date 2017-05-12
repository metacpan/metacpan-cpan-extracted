
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'adjust prereqs to use latest version available',
  'AUTHOR' => 'Pedro Melo <melo@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.92'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Dist-Zilla-Plugin-LatestPrereqs',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'Dist::Zilla::Plugin::LatestPrereqs',
  'PREREQ_PM' => {
    'CPAN' => '1.9402',
    'CPAN::Meta::Prereqs' => '2.101670',
    'Dist::Zilla' => '4.0',
    'Module::CoreList' => '0'
  },
  'VERSION' => '0.4',
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



