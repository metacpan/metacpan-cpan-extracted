
use strict;
use warnings;

BEGIN { require 5.010; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'OpenStreetMap XML file regexp parser',
  'AUTHOR' => 'liosha <liosha@cpan.org>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Geo-Parse-OSM',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Geo::Parse::OSM',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Encode' => '0',
    'Exporter' => '0',
    'HTML::Entities' => '0',
    'IO::Uncompress::AnyUncompress' => '0',
    'List::MoreUtils' => '0',
    'List::Util' => '0'
  },
  'VERSION' => '0.42',
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



