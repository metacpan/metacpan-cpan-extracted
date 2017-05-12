
use strict;
use warnings;

use 5.002;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "run command line script to provide version number",
  "AUTHOR" => "Reid Augustin <reid\@hellosix.com>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-VersionFromScript",
  "EXE_FILES" => [
    "bin/svnversion.pl",
    "bin/git-logs2version.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::Plugin::VersionFromScript",
  "PREREQ_PM" => {
    "Dist::Zilla::Role::TextTemplate" => 0,
    "Dist::Zilla::Role::VersionProvider" => 0,
    "File::Basename" => 0,
    "Moose" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.017",
  "test" => {
    "TESTS" => "t/*.t"
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



