
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Logging to Growl',
  'AUTHOR' => 'Kang-min Liu <gugod@gugod.org>',
  'BUILD_REQUIRES' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'Log-Dispatch-Growl',
  'EXE_FILES' => [],
  'LICENSE' => 'mit',
  'NAME' => 'Log::Dispatch::Growl',
  'PREREQ_PM' => {
    'File::Basename' => '0',
    'Growl::Any' => '0',
    'Log::Dispatch::Output' => '0',
    'Params::Validate' => '0'
  },
  'VERSION' => '1.0.0',
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



