
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "L<Dist::Zilla> plugins for ARJONES",
  "AUTHOR" => "Andrew Jones <andrew\@arjones.co.uk>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-ARJONES",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::PluginBundle::ARJONES",
  "PREREQ_PM" => {
    "Dist::Zilla" => "2.100922",
    "Dist::Zilla::App::Command::cover" => 0,
    "Dist::Zilla::App::Command::perltidy" => 0,
    "Dist::Zilla::Plugin::Clean" => 0,
    "Dist::Zilla::Plugin::ContributorsFromGit" => 0,
    "Dist::Zilla::Plugin::GithubMeta" => 0,
    "Dist::Zilla::Plugin::NoSmartCommentsTests" => 0,
    "Dist::Zilla::Plugin::NoTabsTests" => 0,
    "Dist::Zilla::Plugin::PodWeaver" => 0,
    "Dist::Zilla::Plugin::ReportVersions::Tiny" => 0,
    "Dist::Zilla::Plugin::Test::ChangesHasContent" => 0,
    "Dist::Zilla::Plugin::Test::Compile" => 0,
    "Dist::Zilla::Plugin::Test::Kwalitee" => 0,
    "Dist::Zilla::Plugin::Test::Perl::Critic" => 0,
    "Dist::Zilla::Plugin::Test::Pod::No404s" => 0,
    "Dist::Zilla::Plugin::Test::Portability" => 0,
    "Dist::Zilla::PluginBundle::Basic" => 0,
    "Dist::Zilla::PluginBundle::Git" => 0,
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Moose" => 0,
    "Moose::Autobox" => 0,
    "Pod::Coverage::TrustPod" => 0,
    "Pod::Elemental::Transformer::List" => 0,
    "Pod::Weaver::Config::Assembler" => 0,
    "Pod::Weaver::Section::Contributors" => "0.001",
    "Test::NoSmartComments" => 0,
    "Test::NoTabs" => "1.3",
    "Test::Perl::Critic" => 0,
    "Test::Pod" => "1.41",
    "Test::Pod::Coverage" => "1.08",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.88"
  },
  "VERSION" => "1.133200",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Dist::Zilla" => "2.100922",
  "Dist::Zilla::App::Command::cover" => 0,
  "Dist::Zilla::App::Command::perltidy" => 0,
  "Dist::Zilla::Plugin::Clean" => 0,
  "Dist::Zilla::Plugin::ContributorsFromGit" => 0,
  "Dist::Zilla::Plugin::GithubMeta" => 0,
  "Dist::Zilla::Plugin::NoSmartCommentsTests" => 0,
  "Dist::Zilla::Plugin::NoTabsTests" => 0,
  "Dist::Zilla::Plugin::PodWeaver" => 0,
  "Dist::Zilla::Plugin::ReportVersions::Tiny" => 0,
  "Dist::Zilla::Plugin::Test::ChangesHasContent" => 0,
  "Dist::Zilla::Plugin::Test::Compile" => 0,
  "Dist::Zilla::Plugin::Test::Kwalitee" => 0,
  "Dist::Zilla::Plugin::Test::Perl::Critic" => 0,
  "Dist::Zilla::Plugin::Test::Pod::No404s" => 0,
  "Dist::Zilla::Plugin::Test::Portability" => 0,
  "Dist::Zilla::PluginBundle::Basic" => 0,
  "Dist::Zilla::PluginBundle::Git" => 0,
  "Dist::Zilla::Role::PluginBundle::Easy" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Moose" => 0,
  "Moose::Autobox" => 0,
  "Pod::Coverage::TrustPod" => 0,
  "Pod::Elemental::Transformer::List" => 0,
  "Pod::Weaver::Config::Assembler" => 0,
  "Pod::Weaver::Section::Contributors" => "0.001",
  "Test::More" => "0.88",
  "Test::NoSmartComments" => 0,
  "Test::NoTabs" => "1.3",
  "Test::Perl::Critic" => 0,
  "Test::Pod" => "1.41",
  "Test::Pod::Coverage" => "1.08",
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



