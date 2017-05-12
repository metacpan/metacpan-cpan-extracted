
use strict;
use warnings;

BEGIN { require 5.008001; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => '(you shouldn\'t) use Dist::Zilla like DANIELP',
  'AUTHOR' => 'Daniel Pittman <daniel@rimspace.net>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Dist-Zilla-PluginBundle-DANIELP',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dist::Zilla::PluginBundle::DANIELP',
  'PREREQ_PM' => {
    'Dist::Zilla' => '2.101040',
    'Dist::Zilla::Plugin::ChangelogFromGit' => '0',
    'Dist::Zilla::Plugin::CompileTests' => '0',
    'Dist::Zilla::Plugin::HasVersionTests' => '0',
    'Dist::Zilla::Plugin::MinimumVersionTests' => '0',
    'Dist::Zilla::Plugin::PortabilityTests' => '0',
    'Dist::Zilla::Plugin::ReadmeMarkdownFromPod' => '0',
    'Dist::Zilla::Plugin::ReportVersions::Tiny' => '0',
    'Dist::Zilla::Plugin::SynopsisTests' => '0',
    'Dist::Zilla::Plugin::UnusedVarsTests' => '0',
    'Dist::Zilla::PluginBundle::Git' => '1.102810',
    'Dist::Zilla::Role::PluginBundle::Easy' => '0',
    'Moose' => '0',
    'namespace::autoclean' => '0',
    'utf8' => '0'
  },
  'VERSION' => '1.04',
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



