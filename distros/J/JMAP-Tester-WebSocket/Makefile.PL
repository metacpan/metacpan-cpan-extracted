# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.023.
use strict;
use warnings;

use 5.012;

use ExtUtils::MakeMaker 6.78;

my %WriteMakefileArgs = (
  "ABSTRACT" => "a WebSocket JMAP client made for testing JMAP servers",
  "AUTHOR" => "Matthew Horsfall <wolfsage\@gmail.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.78"
  },
  "DISTNAME" => "JMAP-Tester-WebSocket",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.012",
  "NAME" => "JMAP::Tester::WebSocket",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "IO::Async::Loop" => 0,
    "JMAP::Tester" => "0.101",
    "JMAP::Tester::Response::Paragraph" => 0,
    "JMAP::Tester::Response::Sentence" => 0,
    "JMAP::Tester::Role::Result" => 0,
    "JMAP::Tester::Role::SentenceCollection" => 0,
    "JMAP::Tester::SentenceBroker" => 0,
    "JSON" => 0,
    "JSON::MaybeXS" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "Net::Async::WebSocket::Client" => "0.13",
    "Params::Util" => 0,
    "Protocol::WebSocket::Request" => 0,
    "Scalar::Util" => 0,
    "Try::Tiny" => 0,
    "namespace::clean" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => "0.96",
    "strict" => 0
  },
  "VERSION" => "0.004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dumper" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "IO::Async::Loop" => 0,
  "JMAP::Tester" => "0.101",
  "JMAP::Tester::Response::Paragraph" => 0,
  "JMAP::Tester::Response::Sentence" => 0,
  "JMAP::Tester::Role::Result" => 0,
  "JMAP::Tester::Role::SentenceCollection" => 0,
  "JMAP::Tester::SentenceBroker" => 0,
  "JSON" => 0,
  "JSON::MaybeXS" => 0,
  "Moo" => 0,
  "Moo::Role" => 0,
  "Net::Async::WebSocket::Client" => "0.13",
  "Params::Util" => 0,
  "Protocol::WebSocket::Request" => 0,
  "Scalar::Util" => 0,
  "Test::More" => "0.96",
  "Try::Tiny" => 0,
  "namespace::clean" => 0,
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
