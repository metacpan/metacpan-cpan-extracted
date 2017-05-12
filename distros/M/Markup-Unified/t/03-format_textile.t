#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Markup::Unified;

# Text::Textile formatting
my $min = 2.12;
eval "use Text::Textile $min";
plan skip_all => "Text::Textile $min required for testing Textile formatting" if $@;

my $o = Markup::Unified->new();
ok(defined $o, 'Got a proper Markup::Unified instance');

$o->format('h1. This is a heading', 'textile');

is(
	$o->formatted,
	'<h1>This is a heading</h1>'
);

done_testing();
