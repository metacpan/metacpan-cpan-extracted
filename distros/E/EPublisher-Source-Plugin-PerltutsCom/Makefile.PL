
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Get POD from tutorials published on perltuts.com",
  "AUTHOR" => "Renee Baecker <module\@renee-baecker.de>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "EPublisher-Source-Plugin-PerltutsCom",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "EPublisher::Source::Plugin::PerltutsCom",
  "PREREQ_PM" => {
    "EPublisher" => "0.6",
    "Encode" => 0,
    "File::Basename" => 0,
    "File::Find" => 0,
    "File::Spec" => 0,
    "LWP::Simple" => "0.34",
    "Test::More" => 0,
    "Test::Pod" => "1.14",
    "Test::Pod::Coverage" => "1.08"
  },
  "VERSION" => "0.4",
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



