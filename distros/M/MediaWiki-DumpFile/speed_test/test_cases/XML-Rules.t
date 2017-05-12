#!/usr/bin/env perl

use strict;
use warnings;

use XML::Rules;

binmode(STDOUT, ':utf8');

use Bench;

my ($title, $text);

my $p = XML::Rules->new(rules => [
	_default => undef,
	title => sub { $title = $_[1]->{_content} },
	text => sub { Bench::Article($title, $_[1]->{_content}) },
]);

die "could not open" unless open(FILE, shift(@ARGV));

$p->parse(\*FILE);