
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Use SVK rather than git as your VCS',
  'AUTHOR' => 'Dr Bean <drbean at (a) cpan dot (.) org>',
  'BUILD_REQUIRES' => {
    'Carp' => '0',
    'Dist::Zilla::Tester' => '0',
    'Path::Class' => '0',
    'SVN::Repos' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0',
    'Try::Tiny' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Dist-Zilla-Plugin-SVK',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dist::Zilla::Plugin::SVK',
  'PREREQ_PM' => {
    'Class::MOP' => '0',
    'Cwd' => '0',
    'DateTime' => '0',
    'Dist::Zilla' => '2.100880',
    'Dist::Zilla::Role::AfterRelease' => '0',
    'Dist::Zilla::Role::BeforeRelease' => '0',
    'Dist::Zilla::Role::PluginBundle' => '0',
    'File::Basename' => '0',
    'File::Temp' => '0',
    'List::MoreUtils' => '0',
    'Moose' => '0',
    'Moose::Autobox' => '0',
    'Moose::Role' => '0',
    'MooseX::Has::Sugar' => '0',
    'MooseX::Types::Moose' => '0',
    'SVK' => '0',
    'SVK::Util' => '0',
    'SVK::XD' => '0',
    'String::Formatter' => '0'
  },
  'VERSION' => '0.10',
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



