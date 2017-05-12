
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Document::TriPart::Cabinet ',
  'AUTHOR' => 'Robert Krimen <robertkrimen@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::Most' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Document-TriPart-Cabinet',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Document::TriPart::Cabinet',
  'PREREQ_PM' => {
    'Carp::Clan' => '0',
    'Data::UUID::LibUUID' => '0',
    'DateTime' => '0',
    'DateTimeX::Easy' => '0',
    'Document::TriPart' => '0',
    'File::Temp' => '0',
    'Getopt::Chain' => '0',
    'Moose' => '0',
    'Path::Abstract' => '0',
    'Path::Class' => '0',
    'Term::Prompt' => '0',
    'Text::ASCIITable' => '0'
  },
  'VERSION' => '0.011',
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



