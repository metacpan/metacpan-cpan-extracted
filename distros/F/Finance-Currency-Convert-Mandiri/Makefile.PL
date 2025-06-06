# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.024.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Convert currency using Bank Mandiri",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Finance-Currency-Convert-Mandiri",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "Finance::Currency::Convert::Mandiri",
  "PREREQ_PM" => {
    "Exporter" => "5.57",
    "HTTP::Tiny::Plugin" => "0.004",
    "HTTP::Tiny::Plugin::NewestFirefox" => 0,
    "IO::Socket::SSL" => "2.009",
    "List::Util" => "1.54",
    "Log::ger" => "0.038",
    "Parse::Number::ID" => "0.06",
    "Time::Local" => "1.27",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Slurper" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Perinci::Sub::Property::exit_on_error" => 0,
    "Test::More" => "0.98"
  },
  "VERSION" => "0.002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Exporter" => "5.57",
  "File::Slurper" => 0,
  "File::Spec" => 0,
  "FindBin" => 0,
  "HTTP::Tiny::Plugin" => "0.004",
  "HTTP::Tiny::Plugin::NewestFirefox" => 0,
  "IO::Handle" => 0,
  "IO::Socket::SSL" => "2.009",
  "IPC::Open3" => 0,
  "List::Util" => "1.54",
  "Log::ger" => "0.038",
  "Parse::Number::ID" => "0.06",
  "Perinci::Sub::Property::exit_on_error" => 0,
  "Test::More" => "0.98",
  "Time::Local" => "1.27",
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
