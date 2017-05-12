
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Reformats HTML code blocks coming from Pod verbatim paragraphs',
  'AUTHOR' => 'Emanuele Zeppieri <emazep@cpan.org>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Spec::Functions' => '0',
    'File::Temp' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0.94',
    'Text::Diff' => '0',
    'perl' => '5.004'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'HTML-PodCodeReformat',
  'EXE_FILES' => [
    'bin/reformat-pre.pl'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'HTML::PodCodeReformat',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::Accessor::Fast' => '0',
    'File::Copy' => '0',
    'Getopt::Long' => '0',
    'HTML::Parser' => '3.00',
    'Pod::Usage' => '0',
    'constant' => '0'
  },
  'VERSION' => '0.20000',
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



