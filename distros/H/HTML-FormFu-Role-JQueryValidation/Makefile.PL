
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Client-side JS constraints",
  "AUTHOR" => "Carl Franks <cpan\@fireartist.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTML-FormFu-Role-JQueryValidation",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "HTML::FormFu::Role::JQueryValidation",
  "PREREQ_PM" => {
    "HTML::FormFu" => "1.00",
    "JSON::Any" => "1.29",
    "Moose::Role" => "2.0604",
    "Scalar::Util" => "1.35"
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.99"
  },
  "VERSION" => "1.01",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "HTML::FormFu" => "1.00",
  "JSON::Any" => "1.29",
  "Moose::Role" => "2.0604",
  "Scalar::Util" => "1.35",
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



