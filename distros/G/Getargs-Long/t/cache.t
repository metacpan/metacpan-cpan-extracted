#!/usr/bin/perl

use Getargs::Long qw(ignorecase);
use Test::More tests => 19;

require 't/code.pl';

## same test case as t/nocache.t, only with c*() routines.

package BAR;

sub make { bless {}, shift }

package FOO;

@ISA = qw(BAR);

package main;

my $FOO = FOO->make;
my $BAR = BAR->make;

sub try {
	my ($x, $y, $z, $t, $o, @other) = cxgetargs(@_,
		{
			-strict => 0,
			-extra => 0,
			-inplace => 1,
		},
		'x'		=>	['i', 1],
		-y		=>	['ARRAY', ['a', 'b']],
		'z'		=>	[],
		't'		=>  ['FOO', $FOO],
		-o 		=>  'i',
	);
	return ([$x, $y, $z, $t, $o], \@other, [@_]);
}

sub tryw {
	my ($x, $y, $l, $z, $t) = cxgetargs(@_,
		'x'		=>	['i'],			# integer, non-mandatory
		'y'		=>	['ARRAY', ['a', 'b']],		# Type, non-mandatory, default
		'l'		=>	[],				# anything, non-mandatory

		'z'		=>	undef,			# anything, mandatory
		't'		=> 'BAR'			# Type, mandatory
	);
	return ($x, $y, $z, $t);
}

my @a;
my ($x, $y, $z, $t);
my @other;
my @args;

@a = try(-o => -2, -t => $FOO, -Other => 2, ONE => 3);
($x, $y, $z, $t, $o) = @{$a[0]};
ok($x);
is(ref $y, 'ARRAY');
is($y->[0],'a');
ok(!defined $z);
is(ref $t,'FOO');
is($o,-2);

@other = @{$a[1]};
is(scalar @other,0);

@args = @{$a[2]};
is(@args,4);
is("@args","-Other 2 ONE 3");

eval { try(-t => $FOO) };
like($@,qr/\bargument 'o' missing\b/);

@a = try(-o => 1, -z => 'z', y => [], x => 5);
($x, $y, $z, $t, $o) = @{$a[0]};
is($x,5);
is($z,'z');
is(ref $y,'ARRAY');
is(scalar @$y,0);

eval { try(-o => undef, -z => 'z', y => [], x => 5) };
like($@, qr/'o' cannot be undef\b/);

eval { tryw(-Z => 'BIG Z', y => [], x => 5) };
like($@,qr/\bargument 't' missing\b/);

($x, $y, $z, $t) = tryw(-Z => 'BIG Z', y => [], x => 5, -t => $FOO);
is(ref $t,'FOO');

eval { tryw(-T => 1, -Z => 'BIG Z', y => [], x => 5) };
like($@,qr/'t' must be of type BAR but/);

eval {
	tryw(-T => $BAR, -Z => 'BIG Z', y => [], x => 5,
		-ExtraArg => 'extra-VALUE')
};
like($@,qr/\bswitch: -extraarg\b/);

