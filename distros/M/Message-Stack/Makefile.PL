
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Deal with a "stack" of messages',
  'AUTHOR' => 'Cory G Watson <gphat@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Message-Stack',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Message::Stack',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Moose' => '0',
    'MooseX::Aliases' => '0',
    'MooseX::Storage' => '0',
    'MooseX::Storage::Deferred' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::Moose' => '0'
  },
  'VERSION' => '0.22',
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



