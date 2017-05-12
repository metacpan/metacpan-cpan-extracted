
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Build and upload source package to ppa.launchpad.net",
  "AUTHOR" => "Sergei Svistunov <sergei-svistunov\@yandex.ru>",
  "BUILD_REQUIRES" => {
    "Test::DZil" => 0,
    "Test::More" => "0.88",
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-LaunchpadPPA",
  "EXE_FILES" => [],
  "LICENSE" => "gpl",
  "NAME" => "Dist::Zilla::Plugin::LaunchpadPPA",
  "PREREQ_PM" => {
    "Archive::Tar" => 0,
    "Dist::Zilla::Role::Releaser" => 0,
    "Dpkg::Changelog::Parse" => 0,
    "File::pushd" => 0,
    "Moose" => 0,
    "Path::Class" => 0
  },
  "VERSION" => "0.1",
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



