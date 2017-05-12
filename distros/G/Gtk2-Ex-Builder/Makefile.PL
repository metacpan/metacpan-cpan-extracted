
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Gtk2::Widget Wrapper and Gtk2 Building DSL',
  'AUTHOR' => 'Hojung Youn <amorette@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Gtk2-Ex-Builder',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Gtk2::Ex::Builder',
  'PREREQ_PM' => {
    'Class::Accessor' => '0.34',
    'Sub::Call::Tail' => '0.01'
  },
  'VERSION' => '0.003001',
  'test' => {
    'TESTS' => ''
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



