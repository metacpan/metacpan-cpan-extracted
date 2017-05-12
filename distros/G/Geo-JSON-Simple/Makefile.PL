
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Simplified functions for generating Geo::JSON objects",
  "AUTHOR" => "Torsten Raudssus <torsten\@raudss.us>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Geo-JSON-Simple",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Geo::JSON::Simple",
  "PREREQ_PM" => {
    "Geo::JSON" => 0,
    "List::MoreUtils" => 0
  },
  "TEST_REQUIRES" => {
    "Test::LoadAllModules" => "0.021",
    "Test::More" => "0.98"
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Geo::JSON" => 0,
  "List::MoreUtils" => 0,
  "Test::LoadAllModules" => "0.021",
  "Test::More" => "0.98"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



