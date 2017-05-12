
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Dist::Zilla plugins for me",
  "AUTHOR" => "Logan Bell <loganbell\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::Most" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-LOGIE",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::PluginBundle::LOGIE",
  "PREREQ_PM" => {
    "Dist::Zilla::Plugin::Authority" => 0,
    "Dist::Zilla::Plugin::CheckChangesHasContent" => 0,
    "Dist::Zilla::Plugin::EOLTests" => 0,
    "Dist::Zilla::Plugin::Git" => 0,
    "Dist::Zilla::Plugin::MakeMaker::Awesome" => 0,
    "Dist::Zilla::Plugin::Metadata" => 0,
    "Dist::Zilla::Plugin::NoTabsTests" => 0,
    "Dist::Zilla::Plugin::PodWeaver" => 0,
    "Dist::Zilla::Plugin::TaskWeaver" => 0,
    "Dist::Zilla::Plugin::Test::Compile" => 0,
    "Dist::Zilla::Plugin::Twitter" => 0,
    "LWP::Protocol::https" => 0
  },
  "VERSION" => "0.04",
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



