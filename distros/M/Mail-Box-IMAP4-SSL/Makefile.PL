
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.008.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.17;



my %WriteMakefileArgs = (
  "ABSTRACT" => "handle IMAP4 folders with SSL",
  "AUTHOR" => "David Golden <dagolden\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.17"
  },
  "DISTNAME" => "Mail-Box-IMAP4-SSL",
  "EXE_FILES" => [],
  "LICENSE" => "apache",
  "NAME" => "Mail::Box::IMAP4::SSL",
  "PREREQ_PM" => {
    "IO::Socket::SSL" => "1.12",
    "Mail::Box::IMAP4" => "2.079",
    "Mail::IMAPClient" => "3.02",
    "Mail::Reporter" => "2.079",
    "Mail::Transport::IMAP4" => "2.079",
    "strict" => 0,
    "superclass" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => "0.86",
    "File::Spec::Functions" => 0,
    "IO::CaptureOutput" => "1.06",
    "List::Util" => 0,
    "Mail::Box::Manager" => 0,
    "Probe::Perl" => "0.01",
    "Proc::Background" => "1.08",
    "Test::More" => "0.74"
  },
  "VERSION" => "0.03",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => "0.86",
  "File::Spec::Functions" => 0,
  "IO::CaptureOutput" => "1.06",
  "IO::Socket::SSL" => "1.12",
  "List::Util" => 0,
  "Mail::Box::IMAP4" => "2.079",
  "Mail::Box::Manager" => 0,
  "Mail::IMAPClient" => "3.02",
  "Mail::Reporter" => "2.079",
  "Mail::Transport::IMAP4" => "2.079",
  "Probe::Perl" => "0.01",
  "Proc::Background" => "1.08",
  "Test::More" => "0.74",
  "strict" => 0,
  "superclass" => 0,
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



