
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Release tests for common POD spelling mistakes',
  'AUTHOR' => 'Adam Lesperance <lespea@gmail.com>',
  'BUILD_REQUIRES' => {
    'Dist::Zilla::Plugin::Bootstrap::lib' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'ExtUtils::MakeMaker' => '6.31',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Dist-Zilla-Plugin-SpellingCommonMistakesTests',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dist::Zilla::Plugin::SpellingCommonMistakesTests',
  'PREREQ_PM' => {
    'Dist::Zilla::Plugin::InlineFiles' => '0',
    'Moose' => '0',
    'Pod::Spell::CommonMistakes' => '0',
    'Test::Pod::Spelling::CommonMistakes' => '0',
    'utf8' => '0'
  },
  'VERSION' => '1.001000',
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



