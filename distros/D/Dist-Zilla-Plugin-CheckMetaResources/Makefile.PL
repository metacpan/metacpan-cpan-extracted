
use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Ensure META includes resources",
  "AUTHOR" => "David Golden <dagolden\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Capture::Tiny" => 0,
    "Dist::Zilla::Tester" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Path::Class" => "0.26",
    "Test::More" => "0.88",
    "Try::Tiny" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-CheckMetaResources",
  "EXE_FILES" => [],
  "LICENSE" => "apache",
  "NAME" => "Dist::Zilla::Plugin::CheckMetaResources",
  "PREREQ_PM" => {
    "Dist::Zilla" => 4,
    "Dist::Zilla::Role::BeforeRelease" => 0,
    "Moose" => "0.99",
    "autodie" => "2.00",
    "namespace::autoclean" => "0.09",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.001",
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



