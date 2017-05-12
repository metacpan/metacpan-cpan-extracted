
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Imager.pm helpers for HTML::FormFu file uploads",
  "AUTHOR" => "Carl Franks <cpan\@fireartist.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTML-FormFu-Imager",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "HTML::FormFu::Imager",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Clone" => "0.31",
    "HTML::FormFu" => "1.00",
    "Imager" => 0,
    "Moose" => "1.00",
    "MooseX::Attribute::Chained" => "v1.0.1",
    "Scalar::Util" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0
  },
  "VERSION" => "1.00",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Clone" => "0.31",
  "HTML::FormFu" => "1.00",
  "Imager" => 0,
  "Moose" => "1.00",
  "MooseX::Attribute::Chained" => "v1.0.1",
  "Scalar::Util" => 0,
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



