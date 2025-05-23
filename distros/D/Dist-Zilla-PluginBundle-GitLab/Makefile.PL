# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.024.
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Access GitLab functionality to maintain distros from Dist::Zilla",
  "AUTHOR" => "D Ruth Holloway <ruth\@hiruthie.me>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Dist-Zilla-PluginBundle-GitLab",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008",
  "NAME" => "Dist::Zilla::PluginBundle::GitLab",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Load" => 0,
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "Dist::Zilla::App" => 0,
    "Dist::Zilla::Dist::Minter" => 0,
    "Dist::Zilla::Role::AfterMint" => 0,
    "Dist::Zilla::Role::AfterRelease" => 0,
    "Dist::Zilla::Role::MetaProvider" => 0,
    "Dist::Zilla::Role::PluginBundle::Easy" => 0,
    "Dist::Zilla::Role::TextTemplate" => 0,
    "File::Basename" => 0,
    "Git::Wrapper" => 0,
    "HTTP::Tiny" => 0,
    "JSON::MaybeXS" => 0,
    "List::Util" => 0,
    "Modern::Perl" => 0,
    "Moose" => 0,
    "Try::Tiny" => 0,
    "URL::Encode" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Path::Tiny" => 0,
    "Test2::Tools::Compare" => 0,
    "Test2::Tools::Explain" => 0,
    "Test2::Tools::JSON" => 0,
    "Test2::V0" => 0,
    "Test::DZil" => 0,
    "Test::More" => 0,
    "lib" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.0002",
  "test" => {
    "TESTS" => "t/*.t t/tests/dist/zilla/app/command/*.t t/tests/dist/zilla/plugin/gitlab/*.t t/tests/dist/zilla/pluginbundle/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Class::Load" => 0,
  "Cwd" => 0,
  "Data::Dumper" => 0,
  "Dist::Zilla::App" => 0,
  "Dist::Zilla::Dist::Minter" => 0,
  "Dist::Zilla::Role::AfterMint" => 0,
  "Dist::Zilla::Role::AfterRelease" => 0,
  "Dist::Zilla::Role::MetaProvider" => 0,
  "Dist::Zilla::Role::PluginBundle::Easy" => 0,
  "Dist::Zilla::Role::TextTemplate" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Basename" => 0,
  "File::Spec" => 0,
  "FindBin" => 0,
  "Git::Wrapper" => 0,
  "HTTP::Tiny" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "JSON::MaybeXS" => 0,
  "List::Util" => 0,
  "Modern::Perl" => 0,
  "Moose" => 0,
  "Path::Tiny" => 0,
  "Test2::Tools::Compare" => 0,
  "Test2::Tools::Explain" => 0,
  "Test2::Tools::JSON" => 0,
  "Test2::V0" => 0,
  "Test::DZil" => 0,
  "Test::More" => 0,
  "Try::Tiny" => 0,
  "URL::Encode" => 0,
  "lib" => 0,
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
