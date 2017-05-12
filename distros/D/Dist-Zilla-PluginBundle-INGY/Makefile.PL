
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "BeLike::INGY when you build your dists",
  "AUTHOR" => "Ingy d\303\266t Net <ingy\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-INGY",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::PluginBundle::INGY",
  "PREREQ_PM" => {
    "Dist::Zilla" => "2.100922",
    "Dist::Zilla::Plugin::AutoPrereq" => "1.100130",
    "Dist::Zilla::Plugin::CheckExtraTests" => 0,
    "Dist::Zilla::Plugin::CheckPrereqsIndexed" => 0,
    "Dist::Zilla::Plugin::GithubMeta" => "0.12",
    "Dist::Zilla::Plugin::ReadmeFromPod" => 0,
    "Dist::Zilla::Plugin::ReportVersions::Tiny" => 0,
    "Dist::Zilla::Plugin::Test::ChangesHasContent" => 0,
    "Dist::Zilla::Plugin::Test::Compile" => 0,
    "Dist::Zilla::PluginBundle::Basic" => 0,
    "Dist::Zilla::PluginBundle::Filter" => 0,
    "Dist::Zilla::PluginBundle::Git" => 0,
    "Dist::Zilla::Role::PluginBundle::Config::Slicer" => 0,
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Moose" => 0,
    "Moose::Autobox" => 0,
    "Pod::Elemental" => "0.092970",
    "Pod::Elemental::Transformer::List" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.96",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.0.4",
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



