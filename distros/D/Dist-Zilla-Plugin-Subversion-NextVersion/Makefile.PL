
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "provide a version number by bumping the last SVN release tag",
  "AUTHOR" => "Markus Benning <me\@w3r3wolf.de>",
  "BUILD_REQUIRES" => {
    "SVN::Client" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-Subversion-NextVersion",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::Plugin::Subversion::NextVersion",
  "PREREQ_PM" => {
    "Dist::Zilla" => 4,
    "Dist::Zilla::Role::BeforeRelease" => 0,
    "Dist::Zilla::Role::VersionProvider" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "SVN::Client" => 0,
    "Try::Tiny" => 0,
    "Version::Next" => 0,
    "constant" => 0,
    "strict" => 0,
    "version" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.003",
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



