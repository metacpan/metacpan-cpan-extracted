
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.17;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Makes skeleton modules with Template Toolkit templates (UNMAINTAINED)",
  "AUTHOR" => "David Golden <dagolden\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.17"
  },
  "DISTNAME" => "ExtUtils-ModuleMaker-TT",
  "EXE_FILES" => [
    "bin/makeperlmod"
  ],
  "LICENSE" => "perl",
  "NAME" => "ExtUtils::ModuleMaker::TT",
  "PREREQ_PM" => {
    "Config::Find" => "0.22",
    "Config::General" => "2.29",
    "Data::Dumper" => 0,
    "ExtUtils::ModuleMaker" => "0.46",
    "Getopt::Long" => 0,
    "Path::Class" => "0.15",
    "Template" => "2.14",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Copy" => 0,
    "File::Spec::Functions" => 0,
    "File::pushd" => 1,
    "IPC::Run3" => "0.033",
    "List::Util" => 0,
    "Probe::Perl" => "0.01",
    "Test::Builder" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.94",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Config::Find" => "0.22",
  "Config::General" => "2.29",
  "Data::Dumper" => 0,
  "ExtUtils::MakeMaker" => 0,
  "ExtUtils::ModuleMaker" => "0.46",
  "File::Copy" => 0,
  "File::Spec::Functions" => 0,
  "File::pushd" => 1,
  "Getopt::Long" => 0,
  "IPC::Run3" => "0.033",
  "List::Util" => 0,
  "Path::Class" => "0.15",
  "Probe::Perl" => "0.01",
  "Template" => "2.14",
  "Test::Builder" => 0,
  "Test::More" => 0,
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



