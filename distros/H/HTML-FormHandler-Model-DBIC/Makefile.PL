
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "base class that holds DBIC model role",
  "AUTHOR" => "FormHandler Contributors - see HTML::FormHandler",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTML-FormHandler-Model-DBIC",
  "EXE_FILES" => [
    "script/form_generator.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "HTML::FormHandler::Model::DBIC",
  "PREREQ_PM" => {
    "DBIx::Class" => "0.08250",
    "DBIx::Class::ResultSet::RecursiveUpdate" => "0.25",
    "HTML::FormHandler" => "0.40016",
    "Moose" => "2.0007",
    "namespace::autoclean" => "0.09"
  },
  "TEST_REQUIRES" => {
    "DateTime::Format::MySQL" => 0,
    "DateTime::Format::SQLite" => 0,
    "DateTime::Format::W3CDTF" => 0,
    "Test::Exception" => 0,
    "Test::More" => "0.94"
  },
  "VERSION" => "0.29",
  "test" => {
    "TESTS" => "t/*.t t/xt/*.t"
  }
);


my %FallbackPrereqs = (
  "DBIx::Class" => "0.08250",
  "DBIx::Class::ResultSet::RecursiveUpdate" => "0.25",
  "DateTime::Format::MySQL" => 0,
  "DateTime::Format::SQLite" => 0,
  "DateTime::Format::W3CDTF" => 0,
  "HTML::FormHandler" => "0.40016",
  "Moose" => "2.0007",
  "Test::Exception" => 0,
  "Test::More" => "0.94",
  "namespace::autoclean" => "0.09"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



