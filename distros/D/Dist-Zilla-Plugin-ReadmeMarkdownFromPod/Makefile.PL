
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Automatically convert POD to a README.mkdn for Dist::Zilla",
  "AUTHOR" => "Ryan C. Thompson <rct\@thompsonclan.org>, Jacob Helwig <jhelwig\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-ReadmeMarkdownFromPod",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::Plugin::ReadmeMarkdownFromPod",
  "PREREQ_PM" => {
    "Dist::Zilla::Plugin::ReadmeAnyFromPod" => "0.120120",
    "Moose" => 0,
    "strict" => 0
  },
  "TEST_REQUIRES" => {
    "Carp" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Scalar::Util" => 0,
    "Test::DZil" => 0,
    "Test::More" => "0.94",
    "Test::Most" => 0,
    "autodie" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.141140",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Dist::Zilla::Plugin::ReadmeAnyFromPod" => "0.120120",
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Moose" => 0,
  "Scalar::Util" => 0,
  "Test::DZil" => 0,
  "Test::More" => "0.94",
  "Test::Most" => 0,
  "autodie" => 0,
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



