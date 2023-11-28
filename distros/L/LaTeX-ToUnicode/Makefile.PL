
use strict;
use warnings;

BEGIN { require 5.8.0; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Convert LaTeX commands to Unicode',
  'AUTHOR' => 'Gerhard Gossen <gerhard.gossen@googlemail.com> and Boris Veytsman <boris@varphi.com> and Karl Berry <karl@freefriends.com>',
    'BUILD_REQUIRES' => {
	'Pod-LaTeX' => '0.61'
    },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'LaTeX-ToUnicode',
  'EXE_FILES' => ['script/ltx2unitxt'],
  'LICENSE' => 'perl',
  'NAME' => 'LaTeX::ToUnicode',
  'PREREQ_PM' => {},
  'VERSION_FROM' => 'lib/LaTeX/ToUnicode.pm',
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



