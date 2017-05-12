
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Pull and transform documents from a NoSQL backend',
  'AUTHOR' => 'Nicholas R. Perez <nperez@cpan.org>',
  'BUILD_REQUIRES' => {
    'Digest::SHA1' => '0',
    'Test::Moose' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Document-Transform',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Document::Transform',
  'PREREQ_PM' => {
    'Data::DPath' => '0',
    'Devel::PartialDump' => '0',
    'MongoDB' => '0',
    'MongoDBx::AutoDeref' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::Params::Validate' => '0',
    'MooseX::Types::Moose' => '0',
    'MooseX::Types::Structured' => '0',
    'Throwable::Error' => '0',
    'Try::Tiny' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '1.110530',
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



