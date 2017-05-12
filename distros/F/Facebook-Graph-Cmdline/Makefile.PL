
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Extends Facebook::Graph with embedded HTTP for Oauth and token saving",
  "AUTHOR" => "Andrew Grangaard <spazm\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Moose" => 0,
    "Mouse" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Facebook-Graph-Cmdline",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Facebook::Graph::Cmdline",
  "PREREQ_PM" => {
    "Any::Moose" => 0,
    "Facebook::Graph" => 0,
    "HTTP::Daemon" => "6.00",
    "MooseX::Getopt" => 0,
    "MooseX::SimpleConfig" => 0,
    "MouseX::Getopt" => 0,
    "MouseX::SimpleConfig" => 0,
    "URI" => 0,
    "YAML::Any" => 0
  },
  "VERSION" => "0.123490",
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



