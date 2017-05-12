
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'compare 8-bit scalar data according to the current locale',
  'AUTHOR' => 'Jarkko Hietaniemi <jhi@iki.fi>, Guy Decoux <decoux@moulon.inra.fr>, The Perl 5 Porters',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'I18N-Collate',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'I18N::Collate',
  'PREREQ_PM' => {
    'Exporter' => '0',
    'POSIX' => '0',
    'warnings::register' => '0'
  },
  'VERSION' => '1.02',
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



