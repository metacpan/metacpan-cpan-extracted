
use strict;
use warnings;

use 5.012_000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "easy handling of environment in dotcloud",
  "AUTHOR" => "Flavio Poletti <polettix\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DotCloud-Environment",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "DotCloud::Environment",
  "PREREQ_PM" => {
    "JSON" => "2.53",
    "Sub::Exporter" => 0,
    "Test::Exception" => "0.31",
    "Try::Tiny" => 0,
    "YAML" => "0.72"
  },
  "VERSION" => "0.9.4",
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



