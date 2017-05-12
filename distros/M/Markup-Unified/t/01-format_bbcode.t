#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Markup::Unified;

# HTML::BBCode formatting
my $min = 2.06;
eval "use HTML::BBCode $min";
plan skip_all => "HTML::BBCode $min required for testing BBCode formatting" if $@;

my $o = Markup::Unified->new();
ok(defined $o, 'Got a proper Markup::Unified instance');

$o->format('[b][i][u]This is a simple string[/u][/i][/b]', 'bbcode');

is(
	$o->formatted,
	'<span style="font-weight:bold"><span style="font-style:italic"><span style="text-decoration:underline">This is a simple string</span></span></span>'
);

done_testing();
