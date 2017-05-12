
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "configure Dist::Zilla like RUSSOZ",
  "AUTHOR" => "Alexei Znamensky <russoz\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => "0.88",
    "Test::UseAllModules" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-Author-RUSSOZ",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::PluginBundle::Author::RUSSOZ",
  "PREREQ_PM" => {
    "Dist::Zilla" => "4.102341",
    "Dist::Zilla::Plugin::AutoPrereqs" => 0,
    "Dist::Zilla::Plugin::AutoVersion" => 0,
    "Dist::Zilla::Plugin::GitFmtChanges" => 0,
    "Dist::Zilla::Plugin::GithubMeta" => 0,
    "Dist::Zilla::Plugin::InstallGuide" => 0,
    "Dist::Zilla::Plugin::MetaJSON" => 0,
    "Dist::Zilla::Plugin::OurPkgVersion" => 0,
    "Dist::Zilla::Plugin::PerlTidy" => "0.11",
    "Dist::Zilla::Plugin::PodWeaver" => 0,
    "Dist::Zilla::Plugin::ReadmeFromPod" => 0,
    "Dist::Zilla::Plugin::ReportPhase" => 0,
    "Dist::Zilla::Plugin::ReportVersions::Tiny" => 0,
    "Dist::Zilla::Plugin::Signature" => 0,
    "Dist::Zilla::Plugin::TaskWeaver" => 0,
    "Dist::Zilla::Plugin::Test::Pod::No404s" => 0,
    "Dist::Zilla::Plugin::Test::UseAllModules" => 0,
    "Dist::Zilla::Plugin::VersionFromModule" => 0,
    "Dist::Zilla::PluginBundle::Git" => 0,
    "Dist::Zilla::PluginBundle::TestingMania" => "0.012",
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Moose" => "0.99",
    "Pod::Elemental" => "0.102362",
    "Pod::Elemental::Transformer::List" => 0,
    "Pod::Weaver::Config::Assembler" => 0,
    "Pod::Weaver::Plugin::Encoding" => "0.01",
    "Pod::Weaver::Plugin::EnsureUniqueSections" => 0,
    "Pod::Weaver::Section::BugsAndLimitations" => 0,
    "Pod::Weaver::Section::SeeAlso" => "1.002",
    "Pod::Weaver::Section::Support" => "1.003",
    "Pod::Weaver::Section::WarrantyDisclaimer" => "0.103511",
    "Test::CPAN::Meta::JSON" => 0,
    "Test::Pod::Coverage" => 0,
    "namespace::autoclean" => "0.09",
    "namespace::clean" => 0,
    "strict" => 0,
    "version" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.022",
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



