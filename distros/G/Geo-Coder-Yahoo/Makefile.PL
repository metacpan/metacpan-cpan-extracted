
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Geocode addresses with the Yahoo! API ',
  'AUTHOR' => 'Ask Bjørn Hansen <ask@develooper.com>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Geo-Coder-Yahoo',
  'EXE_FILES' => [
    'bin/ygeocode'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Geo::Coder::Yahoo',
  'PREREQ_PM' => {
    'Encode' => '0',
    'JSON' => '2',
    'LWP::UserAgent' => '0',
    'URI' => '1.36',
    'Yahoo::Search::XML' => '20100614.1'
  },
  'VERSION' => '0.50',
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



