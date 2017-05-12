#!/usr/bin/perl

use Test::More qw(
	no_plan
	);

use warnings;
use strict;

use List::oo qw(L Split);

{
	my $l = Split(qr/,/, 'a');
	isa_ok($l, 'List::oo');
}
{
	my @checks = (
		['a', qr/\s+/, ['a']],
		['a q  e zx', qr/\s+/, [qw(a q e zx)]],
		);
	foreach my $item (@checks) {
		my ($s, $r, $exp) = @$item;
		my $l = Split($r, $s);
		isa_ok($l, 'List::oo');
		is_deeply($l, $exp);
	}
}
{
	my @checks = (
		['a', qr/\s+/],
		['a q  e zx', qr/\s+/],
		);
	foreach my $item (@checks) {
		my ($s, $r) = @$item;
		my @exp = split($r, $s);
		my $l = Split($r, $s);
		isa_ok($l, 'List::oo');
		is_deeply($l, \@exp);
	}
}
{
	my $str = "this is a  string";
	my $get = Split(qr/\s+/, $str)->map(sub {ucfirst})->join('|');
	my $exp = join('|', map({ucfirst} split(/\s+/, $str)));
	ok($get eq $exp);
}
