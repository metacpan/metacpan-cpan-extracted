#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
	my @modules = qw(Dist::Zilla::Plugin::Alien Dist::Zilla::PluginBundle::Alien);
	plan tests => scalar @modules;
	use_ok($_) for @modules;
}
