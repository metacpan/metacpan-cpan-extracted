
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "DBRs Dist::Zilla PluginBundle",
  "AUTHOR" => "Daniel Bruder <dbr\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-DBR",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::PluginBundle::DBR",
  "PREREQ_PM" => {
    "Dist::Zilla" => 0,
    "Dist::Zilla::Plugin::AutoPrereqs" => 0,
    "Dist::Zilla::Plugin::ConfirmRelease" => 0,
    "Dist::Zilla::Plugin::EOLTests" => 0,
    "Dist::Zilla::Plugin::InstallRelease" => 0,
    "Dist::Zilla::Plugin::MetaJSON" => 0,
    "Dist::Zilla::Plugin::ModuleBuild" => 0,
    "Dist::Zilla::Plugin::NoTabsTests" => 0,
    "Dist::Zilla::Plugin::PkgVersion" => 0,
    "Dist::Zilla::Plugin::PodCoverageTests" => 0,
    "Dist::Zilla::Plugin::PodSyntaxTests" => 0,
    "Dist::Zilla::Plugin::PodWeaver" => 0,
    "Dist::Zilla::Plugin::ReadmeFromPod" => 0,
    "Dist::Zilla::Plugin::Run::Release" => 0,
    "Dist::Zilla::Plugin::TaskWeaver" => 0,
    "Dist::Zilla::Plugin::Test::CheckDeps" => 0,
    "Dist::Zilla::Plugin::Test::Compile" => 0,
    "Dist::Zilla::Plugin::Test::Kwalitee" => 0,
    "Dist::Zilla::Plugin::Test::Portability" => 0,
    "Dist::Zilla::Plugin::Test::ReportPrereqs" => 0,
    "Dist::Zilla::Plugin::TestRelease" => 0,
    "Dist::Zilla::PluginBundle::Filter" => 0,
    "MooseX::Declare" => 0
  },
  "VERSION" => "0.024",
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



