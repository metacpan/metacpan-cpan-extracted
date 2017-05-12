
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Support for hierarchical exception classes',
  'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
  'BUILD_REQUIRES' => {
    'Capture::Tiny' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Error-Hierarchy',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Error::Hierarchy',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::Accessor' => '0',
    'Class::Accessor::Complex' => '0',
    'Class::Trigger' => '0',
    'Data::Container' => '0',
    'Data::Dumper' => '0',
    'Data::Inherited' => '0',
    'Data::Miscellany' => '0',
    'Data::UUID' => '0',
    'Error' => '0',
    'Exporter' => '0',
    'Sys::Hostname' => '0',
    'Test::Builder' => '0',
    'Test::Exception' => '0',
    'YAML' => '0',
    'constant' => '0',
    'overload' => '0',
    'parent' => '0'
  },
  'VERSION' => '1.103530',
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



