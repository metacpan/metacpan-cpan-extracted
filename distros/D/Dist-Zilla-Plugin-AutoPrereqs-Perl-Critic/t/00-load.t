#!perl

use strict;
use warnings;

use Test::More;

my @modules = qw(
  Dist::Zilla::Plugin::AutoPrereqs::Perl::Critic
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
