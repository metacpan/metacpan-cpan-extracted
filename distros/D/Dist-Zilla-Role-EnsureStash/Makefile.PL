
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Ensure your plugin has access to a certain stash",
  "AUTHOR" => "Chris Weyl <cweyl\@alumni.drew.edu>",
  "BUILD_REQUIRES" => {
    "Dist::Zilla::Role::BeforeRelease" => 0,
    "Dist::Zilla::Role::Stash" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Moose" => 0,
    "Test::DZil" => 0,
    "Test::Moose::More" => 0,
    "Test::More" => "0.88",
    "aliased" => 0,
    "autobox::Core" => "1.24",
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Role-EnsureStash",
  "EXE_FILES" => [],
  "LICENSE" => "lgpl",
  "NAME" => "Dist::Zilla::Role::EnsureStash",
  "PREREQ_PM" => {
    "Dist::Zilla::Role::RegisterStash" => 0,
    "Moose::Role" => 0,
    "MooseX::AttributeShortcuts" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.002",
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



