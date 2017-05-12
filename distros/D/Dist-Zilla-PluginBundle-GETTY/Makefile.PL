
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "B<DEPRECATED> PLEASE USE L<Dist::Zilla::PluginBundle::Author::GETTY> instead",
  "AUTHOR" => "Torsten Raudssus <torsten\@raudssus.de> L<http://www.raudssus.de/>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.96"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-GETTY",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::PluginBundle::GETTY",
  "PREREQ_PM" => {
    "App::cpanminus" => 0,
    "Dist::Zilla" => "1.092990",
    "Dist::Zilla::Plugin::Authority" => 0,
    "Dist::Zilla::Plugin::BumpVersionFromGit" => 0,
    "Dist::Zilla::Plugin::GithubMeta" => 0,
    "Dist::Zilla::Plugin::InstallRelease" => "0.007",
    "Dist::Zilla::Plugin::PodWeaver" => "3.092971",
    "Dist::Zilla::Plugin::Repository" => 0,
    "Dist::Zilla::Plugin::TaskWeaver" => "0.093330",
    "Dist::Zilla::PluginBundle::Git" => 0,
    "Pod::Elemental" => "0.092970",
    "Pod::Elemental::Transformer::List" => 0,
    "Pod::Weaver" => "3.100310"
  },
  "VERSION" => "0.008",
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



