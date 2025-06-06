# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.043.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Convert GVG into SVG",
  "AUTHOR" => "Timm Murray <tmurray\@wumpus-cave.net>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Graphics-GVG-SVG",
  "LICENSE" => "bsd",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "Graphics::GVG::SVG",
  "PREREQ_PM" => {
    "Graphics::GVG" => "0.4",
    "Moose" => "2.1806",
    "XML::LibXML" => "2.0128",
    "namespace::autoclean" => "0.28"
  },
  "TEST_REQUIRES" => {
    "Test::Pod" => 0
  },
  "VERSION" => "0.4",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Graphics::GVG" => "0.4",
  "Moose" => "2.1806",
  "Test::Pod" => 0,
  "XML::LibXML" => "2.0128",
  "namespace::autoclean" => "0.28"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
