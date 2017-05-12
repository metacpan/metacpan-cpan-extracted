#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Markup::Unified;

# HTML truncation
my $min = 0.20;
eval "use HTML::Truncate $min";
plan skip_all => "HTML::Truncate $min required for testing HTML truncation" if $@;

my $o = Markup::Unified->new();
ok(defined $o, 'Got a proper Markup::Unified instance');

$o->format("<p>This is just a plain HTML paragraph that we're going to truncate.</p>");

is(
	$o->truncate('20c', '...'),
	"<p>This is just a plain...</p>"
);

done_testing();
