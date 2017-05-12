
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "MELO is lazy, this are his rules",
  "AUTHOR" => "Pedro Melo <melo\@simplicidade.org>",
  "BUILD_REQUIRES" => {
    "File::Temp" => 0,
    "Test::More" => "0.98"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-Author-MELO",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Dist::Zilla::PluginBundle::Author::MELO",
  "PREREQ_PM" => {
    "Dist::Zilla" => "4.300002",
    "Dist::Zilla::Plugin::Authority" => "1.005",
    "Dist::Zilla::Plugin::Bootstrap::lib" => "0.01023600",
    "Dist::Zilla::Plugin::Bugtracker" => "1.111080",
    "Dist::Zilla::Plugin::CheckChangesHasContent" => "0.003",
    "Dist::Zilla::Plugin::CheckExtraTests" => "0.004",
    "Dist::Zilla::Plugin::Clean" => "0.02",
    "Dist::Zilla::Plugin::Git::NextVersion" => 0,
    "Dist::Zilla::Plugin::InstallRelease" => "0.007",
    "Dist::Zilla::Plugin::MetaProvides::Package" => "1.12060501",
    "Dist::Zilla::Plugin::MinimumPerl" => "1.003",
    "Dist::Zilla::Plugin::OurPkgVersion" => 0,
    "Dist::Zilla::Plugin::PodWeaver" => 0,
    "Dist::Zilla::Plugin::PrereqsClean" => 0,
    "Dist::Zilla::Plugin::ReportVersions::Tiny" => "1.03",
    "Dist::Zilla::Plugin::Repository" => "0.18",
    "Dist::Zilla::Plugin::Test::Pod::No404s" => "1.001",
    "Dist::Zilla::PluginBundle::Git" => "1.112510",
    "Dist::Zilla::PluginBundle::GitHub" => "0.30",
    "Dist::Zilla::PluginBundle::TestingMania" => "0.014",
    "Dist::Zilla::Role::PluginBundle::Config::Slicer" => 0,
    "List::Util" => 0,
    "Method::Signatures" => 20111020,
    "Moose" => "1.01",
    "Pod::Elemental" => "0.102360",
    "Pod::Elemental::Transformer::List" => 0,
    "Pod::Weaver" => "3.101633",
    "Pod::Weaver::Plugin::Encoding" => 0,
    "Pod::Weaver::Plugin::StopWords" => "1.001005",
    "Pod::Weaver::Plugin::WikiDoc" => "0.093002",
    "Pod::Weaver::Section::Support" => "1.001",
    "Test::CPAN::Meta::JSON" => 0
  },
  "VERSION" => "0.012",
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



