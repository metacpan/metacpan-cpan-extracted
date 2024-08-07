# This Makefile.PL for Math-GMP was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome 0.49.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use 5.010;
use ExtUtils::MakeMaker;

use Alien::Base::Wrapper qw( Alien::GMP !export );

my %WriteMakefileArgs = (
  "ABSTRACT" => "High speed arbitrary size integer math",
  "AUTHOR" => "Shlomi Fish <shlomif\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "Alien::GMP" => "1.08",
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Math-GMP",
  "LICENSE" => "lgpl",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "Math::GMP",
  "PREREQ_PM" => {
    "AutoLoader" => 0,
    "Carp" => 0,
    "DynaLoader" => 0,
    "Exporter" => 0,
    "overload" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Scalar::Util" => 0,
    "Test::More" => 0
  },
  "VERSION" => "2.25",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

%WriteMakefileArgs = (
    %WriteMakefileArgs,
    Alien::Base::Wrapper->mm_args,
);

my %FallbackPrereqs = (
  "AutoLoader" => 0,
  "Carp" => 0,
  "Data::Dumper" => 0,
  "DynaLoader" => 0,
  "Exporter" => 0,
  "File::Spec" => 0,
  "File::Temp" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Scalar::Util" => 0,
  "Test::More" => 0,
  "overload" => 0,
  "strict" => 0,
  "vars" => 0,
  "warnings" => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
