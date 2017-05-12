
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Build your distributions like AMD does",
  "AUTHOR" => "AMD OSRC Tapper Team <tapper\@amd64.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-AMD",
  "EXE_FILES" => [],
  "LICENSE" => "open_source",
  "NAME" => "Dist::Zilla::PluginBundle::AMD",
  "PREREQ_PM" => {
    "Dist::Zilla::Plugin::AssertOS" => 0,
    "Dist::Zilla::Plugin::Authority" => 0,
    "Dist::Zilla::Plugin::AutoPrereqs" => 0,
    "Dist::Zilla::Plugin::CheckChangesHasContent" => 0,
    "Dist::Zilla::Plugin::EOLTests" => "0.02",
    "Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch" => 0,
    "Dist::Zilla::Plugin::Git::Describe" => 0,
    "Dist::Zilla::Plugin::MetaConfig" => 0,
    "Dist::Zilla::Plugin::MetaJSON" => 0,
    "Dist::Zilla::Plugin::MetaResources" => 3,
    "Dist::Zilla::Plugin::NoTabsTests" => 0,
    "Dist::Zilla::Plugin::PodWeaver" => 0,
    "Dist::Zilla::Plugin::StaticVersion" => 0,
    "Dist::Zilla::Plugin::TaskWeaver" => 0,
    "Dist::Zilla::PluginBundle::Classic" => 0,
    "Dist::Zilla::PluginBundle::Filter" => 0,
    "Dist::Zilla::PluginBundle::Git" => 0,
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Method::Signatures::Simple" => 0,
    "Moose" => "1.00",
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Types::Email" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Structured" => "0.20",
    "MooseX::Types::URI" => 0,
    "Pod::Weaver::PluginBundle::AMD" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.011",
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



