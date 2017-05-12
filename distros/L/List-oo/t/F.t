#!/usr/bin/perl

use Test::More qw(
	no_plan
	);

use warnings;
use strict;

BEGIN {
	use_ok('List::oo', qw(F));
}


ok(ref(F{return(1)}) eq 'CODE');
ok(List::oo->can('F'), 'can F');
eval('List::oo->F');
ok(($@ || '') =~ m/^not a method/);
eval('List::oo::F()');
ok(($@ || '') =~ m/^Not enough/, 'prototype check');
eval('List::oo::F("hey")');
ok(($@ || '') =~ m/^Type of/, 'prototype check') or warn $@;

{
	my $l = List::oo->new(qw(a b c));
	my @r1 = $l->map(F{uc})->l;
	my @r2 = $l->map(sub {uc})->l;
	is_deeply(\@r1, \@r2);
}
