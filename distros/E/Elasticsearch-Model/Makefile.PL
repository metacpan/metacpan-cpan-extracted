# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.010.
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Does one thing only: helps to deploy a Moose model and accompanying document classes to Elasticsearch.",
  "AUTHOR" => "Amiri Barksdale <abarksdale\@campusexplorer.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Elasticsearch-Model",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010000",
  "NAME" => "Elasticsearch::Model",
  "PREREQ_PM" => {
    "Class::Load" => 0,
    "List::AllUtils" => 0,
    "Module::Find" => 0,
    "Moose" => 0,
    "Moose::Exporter" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "Search::Elasticsearch" => "6.00",
    "Try::Tiny" => 0
  },
  "TEST_REQUIRES" => {
    "DateTime" => 0,
    "IO::Socket::INET" => 0,
    "IPC::System::Simple" => 0,
    "MooseX::Types::Structured" => 0,
    "Test::Class::Load" => 0,
    "Test::Class::Most" => 0,
    "Test::Moose" => 0,
    "Test::Warnings" => 0,
    "lib" => 0
  },
  "VERSION" => "0.1.5",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Class::Load" => 0,
  "DateTime" => 0,
  "IO::Socket::INET" => 0,
  "IPC::System::Simple" => 0,
  "List::AllUtils" => 0,
  "Module::Find" => 0,
  "Moose" => 0,
  "Moose::Exporter" => 0,
  "Moose::Role" => 0,
  "Moose::Util::TypeConstraints" => 0,
  "MooseX::Types" => 0,
  "MooseX::Types::Moose" => 0,
  "MooseX::Types::Structured" => 0,
  "Search::Elasticsearch" => "6.00",
  "Test::Class::Load" => 0,
  "Test::Class::Most" => 0,
  "Test::Moose" => 0,
  "Test::Warnings" => 0,
  "Try::Tiny" => 0,
  "lib" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
