# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.024.
use strict;
use warnings;

use 5.020000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl interface to the libpwquality C library",
  "AUTHOR" => "Sawyer X",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Lib-PWQuality",
  "LICENSE" => "mit",
  "MIN_PERL_VERSION" => "5.020000",
  "NAME" => "Lib::PWQuality",
  "PREREQ_PM" => {
    "Carp" => 0,
    "FFI::C" => "0.10",
    "FFI::CheckLib" => "0.06",
    "FFI::Platypus" => "1.34",
    "Ref::Util" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => "0.88"
  },
  "VERSION" => "0.002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "ExtUtils::MakeMaker" => 0,
  "FFI::C" => "0.10",
  "FFI::CheckLib" => "0.06",
  "FFI::Platypus" => "1.34",
  "File::Spec" => 0,
  "Ref::Util" => 0,
  "Test::More" => "0.88"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
