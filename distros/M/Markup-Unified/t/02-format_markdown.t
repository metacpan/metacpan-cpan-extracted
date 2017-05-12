#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Markup::Unified;

# Text::Markdown formatting
my $min = '1.0.25';
eval "use Text::Markdown $min";
plan skip_all => "Text::Markdown $min required for testing Markdown formatting" if $@;

my $o = Markup::Unified->new();
ok(defined $o, 'Got a proper Markup::Unified instance');

$o->format('# This is a heading', 'markdown');

is(
	$o->formatted,
	'<h1>This is a heading</h1>
'
);

done_testing();
