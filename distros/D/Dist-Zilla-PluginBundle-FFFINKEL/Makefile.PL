
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "My Dist::Zilla plugin bundle",
  "AUTHOR" => "Matt Finkel <fffinkel\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-FFFINKEL",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::PluginBundle::FFFINKEL",
  "PREREQ_PM" => {
    "Dist::Zilla" => "4.300036",
    "Dist::Zilla::Plugin::Authority" => 0,
    "Dist::Zilla::Plugin::AutoPrereqs" => 0,
    "Dist::Zilla::Plugin::ChangelogFromGit" => 0,
    "Dist::Zilla::Plugin::Clean" => 0,
    "Dist::Zilla::Plugin::EOLTests" => 0,
    "Dist::Zilla::Plugin::Git::Check" => 0,
    "Dist::Zilla::Plugin::Git::NextVersion" => 0,
    "Dist::Zilla::Plugin::PodCoverageTests" => 0,
    "Dist::Zilla::Plugin::PodSyntaxTests" => 0,
    "Dist::Zilla::Plugin::PodWeaver" => 0,
    "Dist::Zilla::Plugin::Twitter" => 0,
    "Dist::Zilla::PluginBundle::Basic" => 0,
    "Dist::Zilla::PluginBundle::Filter" => 0,
    "Dist::Zilla::PluginBundle::Git" => 0,
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Moose" => 0,
    "Pod::Coverage::TrustPod" => 0,
    "Pod::Elemental" => "0.092970",
    "Pod::Elemental::Transformer::List" => 0,
    "Pod::Weaver" => "3.100310",
    "Test::Pod" => "1.41",
    "Test::Pod::Coverage" => "1.08",
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.008",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Dist::Zilla" => "4.300036",
  "Dist::Zilla::Plugin::Authority" => 0,
  "Dist::Zilla::Plugin::AutoPrereqs" => 0,
  "Dist::Zilla::Plugin::ChangelogFromGit" => 0,
  "Dist::Zilla::Plugin::Clean" => 0,
  "Dist::Zilla::Plugin::EOLTests" => 0,
  "Dist::Zilla::Plugin::Git::Check" => 0,
  "Dist::Zilla::Plugin::Git::NextVersion" => 0,
  "Dist::Zilla::Plugin::PodCoverageTests" => 0,
  "Dist::Zilla::Plugin::PodSyntaxTests" => 0,
  "Dist::Zilla::Plugin::PodWeaver" => 0,
  "Dist::Zilla::Plugin::Twitter" => 0,
  "Dist::Zilla::PluginBundle::Basic" => 0,
  "Dist::Zilla::PluginBundle::Filter" => 0,
  "Dist::Zilla::PluginBundle::Git" => 0,
  "Dist::Zilla::Role::PluginBundle::Easy" => 0,
  "Moose" => 0,
  "Pod::Coverage::TrustPod" => 0,
  "Pod::Elemental" => "0.092970",
  "Pod::Elemental::Transformer::List" => 0,
  "Pod::Weaver" => "3.100310",
  "Test::Pod" => "1.41",
  "Test::Pod::Coverage" => "1.08",
  "namespace::autoclean" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



