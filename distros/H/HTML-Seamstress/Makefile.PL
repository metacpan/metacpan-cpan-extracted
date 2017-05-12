
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'HTML::Tree subclass for HTML templating via tree rewriting',
  'AUTHOR' => 'Terrence Brannon <metaperl@gmail.com>',
  'BUILD_REQUIRES' => {
    'Class::Prototyped' => '0',
    'Exporter' => '0',
    'FileHandle' => '0',
    'HTML::PrettyPrinter' => '0',
    'Test::More' => '0',
    'vars' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'HTML-Seamstress',
  'EXE_FILES' => [
    'bin/compile',
    'bin/compile-all.pl',
    'bin/file.html',
    'bin/preamble',
    'bin/sbase.pl',
    'bin/spkg.pl',
    'bin/Simple/Class.pm'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'HTML::Seamstress',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Cwd' => '0',
    'Data::Dumper' => '0',
    'File::Basename' => '0',
    'File::Find' => '0',
    'File::Path' => '0',
    'File::Slurp' => '0',
    'File::Spec' => '0',
    'Getopt::Long' => '0',
    'HTML::Element' => '0',
    'HTML::Element::Library' => '0',
    'HTML::Element::Replacer' => '0',
    'HTML::TreeBuilder' => '0',
    'Pod::Usage' => '0',
    'Set::Array' => '0'
  },
  'VERSION' => '6.112830',
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



