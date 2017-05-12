
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Lightweight general-purpose HTML form generation, with sticky values',
  'AUTHOR' => 'Peter Haworth <pmh@cpan.org>',
  'BUILD_REQUIRES' => {
    'CGI' => '0',
    'ExtUtils::Manifest' => '0',
    'Test::Builder' => '0',
    'Test::More' => '0',
    'Test::NoWarnings' => '0',
    'XML::LibXML' => '0',
    'blib' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'HTML-StickyForm',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'HTML::StickyForm',
  'PREREQ_PM' => {
    'Carp' => '0'
  },
  'VERSION' => '0.08',
  'test' => {
    'TESTS' => 't/*.t t/lib/Test/XML/*.t'
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



