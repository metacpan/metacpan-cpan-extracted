# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.017.
use strict;
use warnings;

use 5.006000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Patch perl source a la Devel::PPPort's buildperl.pl",
  "AUTHOR" => "Chris Williams <chris\@bingosnet.co.uk>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Devel-PatchPerl",
  "EXE_FILES" => [
    "bin/patchperl"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006000",
  "NAME" => "Devel::PatchPerl",
  "PREREQ_PM" => {
    "File::pushd" => "1.00",
    "Getopt::Long" => 0,
    "IO::File" => 0,
    "MIME::Base64" => 0,
    "Module::Pluggable" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0
  },
  "VERSION" => "2.08",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::pushd" => "1.00",
  "Getopt::Long" => 0,
  "IO::File" => 0,
  "MIME::Base64" => 0,
  "Module::Pluggable" => 0,
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
