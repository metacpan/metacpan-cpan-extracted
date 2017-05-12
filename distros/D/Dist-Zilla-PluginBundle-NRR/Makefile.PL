
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Rampage through CPAN-Tokyo the NRR way!",
  "AUTHOR" => "Nathaniel Reindl <nrr\@corvidae.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-NRR",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::PluginBundle::NRR",
  "PREREQ_PM" => {
    "Dist::Zilla" => 0,
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Moose" => 0,
    "Pod::Elemental::Transformer::List" => "0.101620",
    "Pod::Weaver::Config::Assembler" => 0,
    "Pod::Weaver::Plugin::WikiDoc" => 0,
    "Pod::Weaver::Section::Support" => "1.001",
    "charnames" => 0,
    "open" => 0,
    "strict" => 0,
    "strictures" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.121220",
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



