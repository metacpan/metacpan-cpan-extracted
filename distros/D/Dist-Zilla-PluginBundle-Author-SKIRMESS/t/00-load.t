#!perl

use strict;
use warnings;

use Test::More;

my @modules = qw(
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::CPAN::Meta
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::CPAN::Meta::JSON
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::DistManifest
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Kwalitee
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::MinimumVersion
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Mojibake
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::NoTabs
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Perl::Critic
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Pod
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Pod::No404s
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Portability::Files
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Spelling
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Version
  Dist::Zilla::PluginBundle::Author::SKIRMESS
  Dist::Zilla::Role::Author::SKIRMESS::Test::XT
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
