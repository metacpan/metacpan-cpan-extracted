# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Control the GPIO pins on the original NTC Chip",
  "AUTHOR" => "Matthew Mallard <mqtech\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Device-NTCChip-GPIO",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010000",
  "NAME" => "Device::NTCChip::GPIO",
  "PREREQ_PM" => {
    "File::Spec::Functions" => 0,
    "Moose" => 0,
    "Moose::Exporter" => 0
  },
  "VERSION" => "0.101",
  "test" => {
    "TESTS" => ""
  }
);


my %FallbackPrereqs = (
  "File::Spec::Functions" => 0,
  "Moose" => 0,
  "Moose::Exporter" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
