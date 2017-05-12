
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Run external commands at specific phases of Dist::Zilla on regex'd Git branches",
  "AUTHOR" => "Matt Finkel <finkel.matt\@gmail.com> L<http://mfinkel.net/>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-RunByBranch",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::Plugin::RunByBranch",
  "PREREQ_PM" => {
    "Dist::Zilla::Plugin::Run::AfterBuild" => 0,
    "Dist::Zilla::Plugin::Run::AfterMint" => 0,
    "Dist::Zilla::Plugin::Run::AfterRelease" => 0,
    "Dist::Zilla::Plugin::Run::BeforeBuild" => 0,
    "Dist::Zilla::Plugin::Run::BeforeRelease" => 0,
    "Dist::Zilla::Plugin::Run::Release" => 0,
    "Dist::Zilla::Plugin::Run::Test" => 0,
    "Dist::Zilla::Role::Git::Repo" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Dist::Zilla::Tester" => 0,
    "Path::Class" => 0,
    "Test::Git" => 0,
    "Test::More" => 0,
    "lib" => 0
  },
  "VERSION" => "0.214",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



