use if ! ( grep { $_ eq '.' } @INC ), qw[lib .];
use lib 'inc';
use Devel::AssertOS qw[Linux];
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.012000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "API in Perl to recover information about the running Linux OS",
  "AUTHOR" => "Alceu Rodrigues de Freitas Junior <glasswalk3r\@yahoo.com.br>",
  "CONFIGURE_REQUIRES" => {
    "Devel::AssertOS" => "1.21",
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Linux-Info",
  "LICENSE" => "gpl",
  "MIN_PERL_VERSION" => "5.012000",
  "NAME" => "Linux::Info",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::XSAccessor" => "1.19",
    "File::Spec" => 0,
    "Filesys::Df" => "0.92",
    "Hash::Util" => 0,
    "POSIX" => "1.15",
    "Regexp::Common" => "2017060201",
    "Set::Tiny" => "0.04",
    "Time::HiRes" => "1.9764",
    "YAML::XS" => "0.88"
  },
  "TEST_REQUIRES" => {
    "Exporter" => 0,
    "File::Copy" => 0,
    "File::Temp" => 0,
    "Scalar::Util" => 0,
    "Test::Kwalitee" => "1.28",
    "Test::More" => 0,
    "Test::Most" => "0.38",
    "Test::Perl::Critic" => "1.04",
    "Test::Pod" => "1.52",
    "Test::Pod::Coverage" => "1.10",
    "Test::TempDir::Tiny" => "0.018",
    "lib" => 0
  },
  "VERSION" => "2.19",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Class::XSAccessor" => "1.19",
  "Exporter" => 0,
  "File::Copy" => 0,
  "File::Spec" => 0,
  "File::Temp" => 0,
  "Filesys::Df" => "0.92",
  "Hash::Util" => 0,
  "POSIX" => "1.15",
  "Regexp::Common" => "2017060201",
  "Scalar::Util" => 0,
  "Set::Tiny" => "0.04",
  "Test::Kwalitee" => "1.28",
  "Test::More" => 0,
  "Test::Most" => "0.38",
  "Test::Perl::Critic" => "1.04",
  "Test::Pod" => "1.52",
  "Test::Pod::Coverage" => "1.10",
  "Test::TempDir::Tiny" => "0.018",
  "Time::HiRes" => "1.9764",
  "YAML::XS" => "0.88",
  "lib" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
