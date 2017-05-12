
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'ACID transactions on a directory tree',
  'AUTHOR' => 'Yuval Kogman <nothingmuch@woobling.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Directory-Transactional',
  'EXE_FILES' => [],
  'LICENSE' => 'mit',
  'NAME' => 'Directory::Transactional',
  'PREREQ_PM' => {
    'Any::Moose' => '0.07',
    'Data::GUID' => '0',
    'Data::Stream::Bulk' => '0',
    'Directory::Scratch' => '0',
    'File::NFSLock' => '0',
    'File::Path' => '2.07',
    'Hash::Util::FieldHash::Compat' => '0',
    'List::Util' => '0',
    'Path::Class' => '0',
    'Scope::Guard' => '0',
    'Set::Object' => '0',
    'Test::Exception' => '0',
    'Test::TempDir' => '0',
    'Test::use::ok' => '0',
    'Time::HiRes' => '0',
    'namespace::clean' => '0'
  },
  'VERSION' => '0.09',
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



