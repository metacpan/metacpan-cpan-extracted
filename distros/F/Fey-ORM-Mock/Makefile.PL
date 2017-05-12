
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Mock Fey::ORM based classes so you can test without a DBMS",
  "AUTHOR" => "Dave Rolsky <autarch\@urth.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Fey-ORM-Mock",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Fey::ORM::Mock",
  "PREREQ_PM" => {
    "Class::MOP" => "0.69",
    "DBD::Mock" => 0,
    "Fey::DBIManager" => "0.08",
    "Fey::ORM" => "0.33",
    "Moose" => "0.90",
    "MooseX::Params::Validate" => 0,
    "MooseX::StrictConstructor" => 0
  },
  "TEST_REQUIRES" => {
    "Fey::Test" => "0.05",
    "Test::More" => 0
  },
  "VERSION" => "0.06",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Class::MOP" => "0.69",
  "DBD::Mock" => 0,
  "Fey::DBIManager" => "0.08",
  "Fey::ORM" => "0.33",
  "Fey::Test" => "0.05",
  "Moose" => "0.90",
  "MooseX::Params::Validate" => 0,
  "MooseX::StrictConstructor" => 0,
  "Test::More" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



