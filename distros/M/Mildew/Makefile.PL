
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'the mildew Perl6 compiler',
  'AUTHOR' => 'Pawel Murias <pawelmurias@gmail.com>, Daniel Ruoso <daniel@ruoso.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Mildew',
  'EXE_FILES' => [
    'bin/mildew'
  ],
  'LICENSE' => 'artistic_2',
  'NAME' => 'Mildew',
  'PREREQ_PM' => {
    'Bread::Board' => '0.13',
    'Data::Dumper::Concise' => '1.200',
    'Digest::MD4' => '0',
    'File::Slurp' => '0',
    'Forest::Tree' => '0.08',
    'Graph::Easy' => '0.69',
    'Moose' => '1.03',
    'MooseX::Declare' => '0.33',
    'Regexp::Grammars' => '1.002',
    'STD' => '0.05',
    'Set::Object' => '1.26',
    'YAML::XS' => '0'
  },
  'VERSION' => '0.05',
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



