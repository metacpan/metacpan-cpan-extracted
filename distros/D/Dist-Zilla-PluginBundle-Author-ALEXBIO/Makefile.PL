
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share module => "Dist::Zilla::MintingProfile::Author::ALEXBIO", "profiles";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Plugin bundle used by ALEXBIO",
  "AUTHOR" => "Alessandro Ghedini <alexbio\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-Author-ALEXBIO",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::PluginBundle::Author::ALEXBIO",
  "PREREQ_PM" => {
    "Config::Identity" => 0,
    "Dist::Zilla" => 0,
    "Dist::Zilla::Plugin::Clean" => 0,
    "Dist::Zilla::Plugin::Git" => 0,
    "Dist::Zilla::Plugin::GitHub" => "0.35",
    "Dist::Zilla::Plugin::InstallRelease" => 0,
    "Dist::Zilla::Plugin::MakeMaker::Awesome" => 0,
    "Dist::Zilla::Plugin::Test::CheckManifest" => 0,
    "Dist::Zilla::Plugin::Test::Compile" => "2.033",
    "Dist::Zilla::Role::MintingProfile::ShareDir" => 0,
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Moose" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "2.07",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Config::Identity" => 0,
  "Dist::Zilla" => 0,
  "Dist::Zilla::Plugin::Clean" => 0,
  "Dist::Zilla::Plugin::Git" => 0,
  "Dist::Zilla::Plugin::GitHub" => "0.35",
  "Dist::Zilla::Plugin::InstallRelease" => 0,
  "Dist::Zilla::Plugin::MakeMaker::Awesome" => 0,
  "Dist::Zilla::Plugin::Test::CheckManifest" => 0,
  "Dist::Zilla::Plugin::Test::Compile" => "2.033",
  "Dist::Zilla::Role::MintingProfile::ShareDir" => 0,
  "Dist::Zilla::Role::PluginBundle::Easy" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Moose" => 0,
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

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


