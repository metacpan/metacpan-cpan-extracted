
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Handle multi-page/stage forms",
  "AUTHOR" => "Carl Franks <cpan\@fireartist.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTML-FormFu-MultiForm",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "HTML::FormFu::MultiForm",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Clone" => "0.31",
    "Crypt::CBC" => 0,
    "Crypt::DES" => 0,
    "HTML::FormFu" => "1.00",
    "List::MoreUtils" => 0,
    "Moose" => "1.00",
    "MooseX::Attribute::Chained" => "v1.0.1",
    "Scalar::Util" => 0,
    "Storable" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Aggregate::Nested" => "0.371",
    "Test::More" => "0.92"
  },
  "VERSION" => "1.00",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Clone" => "0.31",
  "Crypt::CBC" => 0,
  "Crypt::DES" => 0,
  "HTML::FormFu" => "1.00",
  "List::MoreUtils" => 0,
  "Moose" => "1.00",
  "MooseX::Attribute::Chained" => "v1.0.1",
  "Scalar::Util" => 0,
  "Storable" => 0,
  "Test::Aggregate::Nested" => "0.371",
  "Test::More" => "0.92"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



