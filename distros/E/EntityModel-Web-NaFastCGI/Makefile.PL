
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'L<Net::Async::FastCGI> support for L<EntityModel::Web>',
  'AUTHOR' => 'Tom Molesworth <cpan@entitymodel.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'EntityModel-Web-NaFastCGI',
  'EXE_FILES' => [
    'bin/daemon.fcgi'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'EntityModel::Web::NaFastCGI',
  'PREREQ_PM' => {
    'EntityModel::Web' => '0.002',
    'Net::Async::FastCGI' => '0.23',
    'Time::Checkpoint::Sequential' => '0.002'
  },
  'VERSION' => '0.002',
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



