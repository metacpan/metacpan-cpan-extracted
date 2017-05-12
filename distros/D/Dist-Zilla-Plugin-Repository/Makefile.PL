
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Automatically sets repository URL from svn/svk/Git checkout for Dist::Zilla",
  "AUTHOR" => "Fayland Lam <fayland\@gmail.com>, Ricardo SIGNES <rjbs\@cpan.org>, Moritz Onken <onken\@netcubed.de>, Christopher J. Madsen <perl\@cjmweb.net>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-Repository",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::Plugin::Repository",
  "PREREQ_PM" => {
    "Dist::Zilla" => "4.102340"
  },
  "TEST_REQUIRES" => {
    "Dist::Zilla::Tester" => "4.102340",
    "Test::More" => "0.88"
  },
  "VERSION" => "0.20",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Dist::Zilla" => "4.102340",
  "Dist::Zilla::Tester" => "4.102340",
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



