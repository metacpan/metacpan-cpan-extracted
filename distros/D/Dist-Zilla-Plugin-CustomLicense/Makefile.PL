
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'setting legal stuff of Dist::Zilla while keeping control',
  'AUTHOR' => 'Flavio Poletti <polettix@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Dist-Zilla-Plugin-CustomLicense',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'Dist::Zilla::Plugin::CustomLicense',
  'PREREQ_PM' => {
    'Dist::Zilla' => '4.102342',
    'Moose' => '0',
    'Software::License' => '0.103000',
    'Text::Template' => '0'
  },
  'VERSION' => '1.0.2',
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



