# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.010.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "use JSON natively with LWP objects",
  "AUTHOR" => "Sam Kington <skington\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "LWP-JSON-Tiny",
  "LICENSE" => "perl",
  "NAME" => "LWP::JSON::Tiny",
  "PREREQ_PM" => {
    "Encode" => 0,
    "HTTP::Request" => 0,
    "HTTP::Request::Common" => "6.07",
    "HTTP::Response" => 0,
    "JSON::MaybeXS" => 0,
    "LWP" => 0,
    "LWP::UserAgent" => 0,
    "Scalar::Util" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "FindBin" => 0,
    "HTTP::Message" => "6.04",
    "HTTP::Request::Common" => "6.07",
    "JSON::MaybeXS" => 0,
    "LWP" => 0,
    "LWP::Protocol" => 0,
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "if" => 0,
    "lib" => 0,
    "parent" => 0,
    "utf8" => 0
  },
  "VERSION" => "0.014",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Encode" => 0,
  "FindBin" => 0,
  "HTTP::Message" => "6.04",
  "HTTP::Request" => 0,
  "HTTP::Request::Common" => "6.07",
  "HTTP::Response" => 0,
  "JSON::MaybeXS" => 0,
  "LWP" => 0,
  "LWP::Protocol" => 0,
  "LWP::UserAgent" => 0,
  "Scalar::Util" => 0,
  "Test::Fatal" => 0,
  "Test::More" => 0,
  "if" => 0,
  "lib" => 0,
  "parent" => 0,
  "strict" => 0,
  "utf8" => 0,
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
