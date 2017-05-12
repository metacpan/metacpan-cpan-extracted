
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Dist::Zilla Releaser plugin for uploading to CPAN::Site mirror.",
  "AUTHOR" => "Stephen Cardie <stephenca\@ls26.net>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-UploadToCpanSite",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::Plugin::UploadToCpanSite",
  "PREREQ_PM" => {
    "Dist::Zilla" => "4.3",
    "Dist::Zilla::Role::Releaser" => 0,
    "English" => 0,
    "File::Spec" => 0,
    "Moose" => 0,
    "MooseX::Has::Sugar" => 0,
    "MooseX::Types::Moose" => 0,
    "Net::SCP" => 0,
    "Net::SSH" => 0,
    "Try::Tiny" => 0,
    "common::sense" => 0,
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "File::Temp" => 0,
    "Test::More" => "0.88",
    "blib" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.132210",
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



