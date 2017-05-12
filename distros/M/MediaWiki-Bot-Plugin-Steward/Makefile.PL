
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A plugin to MediaWiki::Bot providing steward functions',
  'AUTHOR' => 'Mike.lifeguard <mike.lifeguard@gmail.com>, patch and bug report contributors',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'MediaWiki-Bot-Plugin-Steward',
  'EXE_FILES' => [],
  'LICENSE' => 'gpl',
  'NAME' => 'MediaWiki::Bot::Plugin::Steward',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Exporter' => '0',
    'HTML::TreeBuilder' => '0',
    'MediaWiki::Bot' => '3.0.0',
    'Net::CIDR' => '0',
    'URI::Escape' => '0',
    'WWW::Mechanize' => '1.30'
  },
  'VERSION' => '0.0003',
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



