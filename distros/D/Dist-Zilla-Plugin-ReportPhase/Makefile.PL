
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Log every role use in every phase executed.",
  "AUTHOR" => "Stirling Westrup <swestrup\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-ReportPhase",
  "EXE_FILES" => [],
  "LICENSE" => "gpl",
  "NAME" => "Dist::Zilla::Plugin::ReportPhase",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Dist::Zilla::Role::AfterBuild" => 0,
    "Dist::Zilla::Role::AfterMint" => 0,
    "Dist::Zilla::Role::AfterRelease" => 0,
    "Dist::Zilla::Role::BeforeArchive" => 0,
    "Dist::Zilla::Role::BeforeBuild" => 0,
    "Dist::Zilla::Role::BeforeMint" => 0,
    "Dist::Zilla::Role::BeforeRelease" => 0,
    "Dist::Zilla::Role::BuildRunner" => 0,
    "Dist::Zilla::Role::ConfigDumper" => 0,
    "Dist::Zilla::Role::FileFinder" => 0,
    "Dist::Zilla::Role::FileGatherer" => 0,
    "Dist::Zilla::Role::FileMunger" => 0,
    "Dist::Zilla::Role::FilePruner" => 0,
    "Dist::Zilla::Role::InstallTool" => 0,
    "Dist::Zilla::Role::MetaProvider" => 0,
    "Dist::Zilla::Role::MintingProfile" => 0,
    "Dist::Zilla::Role::ModuleMaker" => 0,
    "Dist::Zilla::Role::PrereqSource" => 0,
    "Dist::Zilla::Role::Releaser" => 0,
    "Dist::Zilla::Role::ShareDir" => 0,
    "Dist::Zilla::Role::TestRunner" => 0,
    "Dist::Zilla::Role::VersionProvider" => 0,
    "Moose" => 0,
    "Moose::Autobox" => 0
  },
  "VERSION" => "0.03",
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



