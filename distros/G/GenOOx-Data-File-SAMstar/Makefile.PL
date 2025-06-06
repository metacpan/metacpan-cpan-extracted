
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.015.
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "GenOO framework extension to read SAM files created by the STAR aligner",
  "AUTHOR" => "Emmanouil \"Manolis\" Maragkakis <mns.marag\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "GenOOx-Data-File-SAMstar",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "GenOOx::Data::File::SAMstar",
  "PREREQ_PM" => {
    "GenOO::Data::File::SAM::Record" => 0,
    "Modern::Perl" => 0,
    "Moose" => 0,
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Class" => 0,
    "Test::Class::Load" => 0,
    "Test::Moose" => 0,
    "Test::More" => 0,
    "Test::Most" => 0,
    "base" => 0,
    "strict" => 0
  },
  "VERSION" => "0.0.3",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "GenOO::Data::File::SAM::Record" => 0,
  "Modern::Perl" => 0,
  "Moose" => 0,
  "Test::Class" => 0,
  "Test::Class::Load" => 0,
  "Test::Moose" => 0,
  "Test::More" => 0,
  "Test::Most" => 0,
  "base" => 0,
  "namespace::autoclean" => 0,
  "strict" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



