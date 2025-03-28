# This Makefile.PL for Mail-Exim-ACL-Geolocation was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome 0.49.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use 5.016;
use ExtUtils::MakeMaker;

die "OS unsupported\n" if $^O eq 'MSWin32';

my %WriteMakefileArgs = (
  "ABSTRACT" => "Map IP addresses to location information",
  "AUTHOR" => "Andreas V\x{f6}gele <voegelas\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Mail-Exim-ACL-Geolocation",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.016",
  "NAME" => "Mail::Exim::ACL::Geolocation",
  "PREREQ_PM" => {
    "Exporter" => 0,
    "IP::Geolocation::MMDB" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec::Functions" => 0,
    "Test::More" => 0
  },
  "VERSION" => "1.005",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Exporter" => 0,
  "File::Spec::Functions" => 0,
  "IP::Geolocation::MMDB" => 0,
  "Test::More" => 0,
  "utf8" => 0,
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
