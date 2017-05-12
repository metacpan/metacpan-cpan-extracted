
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'trap multiple calls to Log::Log4perl::easy_init',
  'AUTHOR' => 'Chisel Wright <chisel@chizography.net>',
  'BUILD_REQUIRES' => {
    'FindBin::libs' => '0',
    'Test::More' => '0',
    'Test::Warn' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Log-Log4perl-Warn-Multiple-EasyInit',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Log::Log4perl::Warn::Multiple::EasyInit',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Log::Log4perl' => '0',
    'Test::More' => '0',
    'Test::Warn' => '0'
  },
  'VERSION' => '0.0.1',
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



