
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Inject into a CPAN::Mini mirror',
  'AUTHOR' => 'Peter Shangov <pshangov@yahoo.com>',
  'BUILD_REQUIRES' => {
    'Directory::Scratch' => '0',
    'Dist::Zilla::Tester' => '0',
    'File::Find' => '0',
    'Path::Class' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Dist-Zilla-Plugin-Inject',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dist::Zilla::Plugin::Inject',
  'PREREQ_PM' => {
    'Class::Load' => '0',
    'Dist::Zilla::Role::Releaser' => '0',
    'File::Temp' => '0',
    'Moose' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'Try::Tiny' => '0'
  },
  'VERSION' => '0.001',
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



