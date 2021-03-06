# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.011.
use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Integrate HTML::FormFu with DBIx::Class",
  "AUTHOR" => "Carl Franks <cpan\@fireartist.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "HTML-FormFu-Model-DBIC",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008001",
  "NAME" => "HTML::FormFu::Model::DBIC",
  "PREREQ_PM" => {
    "DBD::SQLite" => 0,
    "DBIx::Class" => "0.08108",
    "HTML::FormFu" => "2.00",
    "List::MoreUtils" => 0,
    "MooseX::Attribute::Chained" => "1.0.2",
    "Storable" => 0,
    "Task::Weaken" => 0
  },
  "TEST_REQUIRES" => {
    "DateTime::Format::SQLite" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Locale::Maketext" => 0,
    "SQL::Translator" => "0.11016",
    "Test::More" => "0.99"
  },
  "VERSION" => "2.03",
  "test" => {
    "TESTS" => "t/*.t t/constraints/*.t t/create/*.t t/default_values/*.t t/options_from_model/*.t t/update/*.t t/x_roundtrip/*.t"
  }
);


my %FallbackPrereqs = (
  "DBD::SQLite" => 0,
  "DBIx::Class" => "0.08108",
  "DateTime::Format::SQLite" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "HTML::FormFu" => "2.00",
  "List::MoreUtils" => 0,
  "Locale::Maketext" => 0,
  "MooseX::Attribute::Chained" => "1.0.2",
  "SQL::Translator" => "0.11016",
  "Storable" => 0,
  "Task::Weaken" => 0,
  "Test::More" => "0.99"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
