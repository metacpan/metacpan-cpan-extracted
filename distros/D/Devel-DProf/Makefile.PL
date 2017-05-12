
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'a B<DEPRECATED> Perl code profiler',
  'AUTHOR' => 'The Perl 5 Porters',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Devel-DProf',
  'EXE_FILES' => [
    'bin/dprofpp'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Devel::DProf',
  'PREREQ_PM' => {
    'XSLoader' => '0'
  },
  'VERSION' => '20110802.00',
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

$WriteMakefileArgs{INSTALLDIRS} = 'perl'
    if $] >= 5.009005 && $] <= 5.011000;

WriteMakefile(%WriteMakefileArgs);



