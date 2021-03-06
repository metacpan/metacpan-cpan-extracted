# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "throw HTTP-Errors as (Exception::Class-) Exceptions",
  "AUTHOR" => "Thomas M\x{fc}ller <tmueller\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "HTTP-Exception",
  "LICENSE" => "perl",
  "NAME" => "HTTP::Exception",
  "PREREQ_PM" => {
    "Exception::Class" => "1.29",
    "HTTP::Status" => "5.817",
    "Scalar::Util" => "1.22",
    "Test::Exception" => "0.29",
    "Test::More" => "0.88",
    "Test::NoWarnings" => "1.04",
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.04007",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Exception::Class" => "1.29",
  "HTTP::Status" => "5.817",
  "Scalar::Util" => "1.22",
  "Test::Exception" => "0.29",
  "Test::More" => "0.88",
  "Test::NoWarnings" => "1.04",
  "base" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
