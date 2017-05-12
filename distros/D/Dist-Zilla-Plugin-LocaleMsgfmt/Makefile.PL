
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'compiles .po files to .mo files with Local::Msgfmt',
  'AUTHOR' => 'Patrick Donelan <pdonelan@cpan.org>',
  'BUILD_REQUIRES' => {
    'Dist::Zilla' => '1.093250',
    'Dist::Zilla::Tester' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::File' => '0',
    'Test::More' => '0',
    'Test::Warn' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Dist-Zilla-Plugin-LocaleMsgfmt',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dist::Zilla::Plugin::LocaleMsgfmt',
  'PREREQ_PM' => {
    'Dist::Zilla::Role::BeforeBuild' => '0',
    'Locale::Msgfmt' => '0.14',
    'Moose' => '0',
    'MooseX::Has::Sugar' => '0',
    'Path::Class' => '0'
  },
  'VERSION' => '1.203',
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



