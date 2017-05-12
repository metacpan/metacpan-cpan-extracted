
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'SOAP interface to Hopkins',
  'AUTHOR' => 'Mike Eldridge <diz@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.42'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Hopkins-Plugin-RPC',
  'EXE_FILES' => [
    'bin/hopkins'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Hopkins::Plugin::RPC',
  'PREREQ_PM' => {
    'Class::Accessor::Fast' => '0.31',
    'Getopt::Attribute' => '1.44',
    'Hopkins' => '0.900',
    'POE::Component::Server::SOAP' => '1.11',
    'String::Escape' => '2002.001'
  },
  'VERSION' => '0.900',
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



