# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.025.
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Convert exported Perl constants to JavaScript",
  "AUTHOR" => "Robert Rothenberg <rrwo\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "JavaScript-Const-Exporter",
  "EXE_FILES" => [
    "bin/js-const"
  ],
  "LICENSE" => "artistic_2",
  "MIN_PERL_VERSION" => "5.010000",
  "NAME" => "JavaScript::Const::Exporter",
  "PREREQ_PM" => {
    "Carp" => 0,
    "JSON::MaybeXS" => 0,
    "Module::Load" => 0,
    "Moo" => "1.002000",
    "MooX::Options" => 0,
    "Package::Stash" => 0,
    "Path::Tiny" => 0,
    "Ref::Util" => 0,
    "Sub::Identify" => "0.06",
    "Types::Common::String" => 0,
    "Types::Standard" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Exporter" => 0,
    "File::Spec" => 0,
    "Module::Metadata" => 0,
    "Test2::V0" => 0,
    "Test::Deep" => "1.127",
    "Test::Deep::Regexp" => 0,
    "Test::Deep::Set" => 0,
    "Test::Differences" => 0,
    "Test::More" => 0,
    "Test::Most" => "0.35",
    "Test::Script" => "1.23",
    "Test::Warnings" => "0.028",
    "constant" => 0,
    "lib" => 0,
    "version" => "0.77"
  },
  "VERSION" => "v0.1.7",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Exporter" => 0,
  "File::Spec" => 0,
  "JSON::MaybeXS" => 0,
  "Module::Load" => 0,
  "Module::Metadata" => 0,
  "Moo" => "1.002000",
  "MooX::Options" => 0,
  "Package::Stash" => 0,
  "Path::Tiny" => 0,
  "Ref::Util" => 0,
  "Sub::Identify" => "0.06",
  "Test2::V0" => 0,
  "Test::Deep" => "1.127",
  "Test::Deep::Regexp" => 0,
  "Test::Deep::Set" => 0,
  "Test::Differences" => 0,
  "Test::More" => 0,
  "Test::Most" => "0.35",
  "Test::Script" => "1.23",
  "Test::Warnings" => "0.028",
  "Types::Common::String" => 0,
  "Types::Standard" => 0,
  "constant" => 0,
  "lib" => 0,
  "namespace::autoclean" => 0,
  "strict" => 0,
  "version" => "0.77",
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
