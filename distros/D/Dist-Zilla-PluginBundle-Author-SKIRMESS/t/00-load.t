#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.032

use Test::More;

use lib qw(lib);

my @modules = qw(
  Dist::Zilla::Plugin::Author::SKIRMESS::InsertVersion
  Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase
  Dist::Zilla::PluginBundle::Author::SKIRMESS
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}
