
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.31;

use File::ShareDir::Install;
install_share module => "Dist::Zilla::MintingProfile::Catalyst", "profiles";


my %WriteMakefileArgs = (
  'ABSTRACT' => 'set of plugins for working with Catalyst',
  'AUTHOR' => 'Caleb Cushing <xenoterracide@gmail.com>, Tomas Doran <bobtfish@bobtfish.net>',
  'BUILD_REQUIRES' => {
    'Carp' => '0',
    'Dist::Zilla::Tester' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'FindBin' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'File::ShareDir::Install' => '0.03'
  },
  'DISTNAME' => 'Dist-Zilla-Plugin-Catalyst',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'Dist::Zilla::Plugin::Catalyst',
  'PREREQ_PM' => {
    'Catalyst::Helper' => '1.30',
    'Dist::Zilla::File::FromCode' => '0',
    'Dist::Zilla::File::InMemory' => '0',
    'Dist::Zilla::Role::MintingProfile::ShareDir' => '0',
    'Dist::Zilla::Role::ModuleMaker' => '0',
    'Moose' => '0',
    'Path::Class' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.15',
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

package
MY;
use File::ShareDir::Install qw(postamble);


