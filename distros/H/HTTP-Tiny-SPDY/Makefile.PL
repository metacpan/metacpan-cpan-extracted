
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.17;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A subclass of HTTP::Tiny with SPDY support",
  "AUTHOR" => "Michal Wojciechowski <odyniec\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.17"
  },
  "DISTNAME" => "HTTP-Tiny-SPDY",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "HTTP::Tiny::SPDY",
  "PREREQ_PM" => {
    "HTTP::Tiny" => 0,
    "HTTP::Tiny::Handle" => 0,
    "IO::Socket" => 0,
    "IO::Socket::SSL" => "1.56",
    "Net::SPDY::Session" => 0,
    "Net::SSLeay" => "1.49",
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Basename" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "IO::Dir" => 0,
    "IO::File" => 0,
    "IO::Handle" => 0,
    "IO::Socket::INET" => 0,
    "IO::Socket::SSL" => "1.56",
    "IPC::Cmd" => 0,
    "IPC::Open3" => 0,
    "List::Util" => 0,
    "Mozilla::CA" => 0,
    "Test::More" => "0.96",
    "open" => 0
  },
  "VERSION" => "0.020",
  "test" => {
    "TESTS" => "t/*.t t/http_tiny/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dumper" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Basename" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "File::Temp" => 0,
  "HTTP::Tiny" => 0,
  "HTTP::Tiny::Handle" => 0,
  "IO::Dir" => 0,
  "IO::File" => 0,
  "IO::Handle" => 0,
  "IO::Socket" => 0,
  "IO::Socket::INET" => 0,
  "IO::Socket::SSL" => "1.56",
  "IPC::Cmd" => 0,
  "IPC::Open3" => 0,
  "List::Util" => 0,
  "Mozilla::CA" => 0,
  "Net::SPDY::Session" => 0,
  "Net::SSLeay" => "1.49",
  "Test::More" => "0.96",
  "open" => 0,
  "parent" => 0,
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



