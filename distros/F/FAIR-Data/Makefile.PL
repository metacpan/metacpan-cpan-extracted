# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.008.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "a set of packages that assist with creating infrastructures that conform to the FAIR Data Principles",
  "AUTHOR" => "Mark Denis Wilkinson (markw [at] illuminae [dot] com)",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "FAIR-Data",
  "LICENSE" => "apache",
  "NAME" => "FAIR::Data",
  "PREREQ_PM" => {
    "JSON" => 0,
    "LWP::Simple" => 0,
    "Log::Log4perl" => 0,
    "Moose" => 0,
    "RDF::NS" => 0,
    "RDF::Query" => 0,
    "RDF::Trine::Model" => 0,
    "RDF::Trine::Node::Literal" => 0,
    "RDF::Trine::Node::Resource" => 0,
    "RDF::Trine::Parser" => 0,
    "RDF::Trine::Serializer" => 0,
    "RDF::Trine::Store::Memory" => 0,
    "Scalar::Util" => 0,
    "URI::Escape" => 0,
    "UUID::Generator::PurePerl" => 0
  },
  "TEST_REQUIRES" => {
    "File::Slurp" => 0,
    "IO::String" => 0
  },
  "VERSION" => "1.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::Slurp" => 0,
  "IO::String" => 0,
  "JSON" => 0,
  "LWP::Simple" => 0,
  "Log::Log4perl" => 0,
  "Moose" => 0,
  "RDF::NS" => 0,
  "RDF::Query" => 0,
  "RDF::Trine::Model" => 0,
  "RDF::Trine::Node::Literal" => 0,
  "RDF::Trine::Node::Resource" => 0,
  "RDF::Trine::Parser" => 0,
  "RDF::Trine::Serializer" => 0,
  "RDF::Trine::Store::Memory" => 0,
  "Scalar::Util" => 0,
  "URI::Escape" => 0,
  "UUID::Generator::PurePerl" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
