
use strict;
use warnings;

BEGIN { require 5.008001; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Build simple trees of files and directories.',
  'AUTHOR' => 'Luc St-Louis <lucs@cpan.org>',
  'BUILD_REQUIRES' => {
    'FindBin' => '0',
    'Test::More' => '0',
    'Test::Usage' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'File-TreeBuilder',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'File::TreeBuilder',
  'PREREQ_PM' => {
    'Exporter' => '0',
    'File::Temp' => '0'
  },
  'VERSION' => '0.02',
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



