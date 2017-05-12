#!./perl

use Getargs::Long;
use Test::More tests => 12;

require 't/code.pl';

package BAR;

sub make { bless {}, shift }

package FOO;

@ISA = qw(BAR);

package main;

my $FOO = FOO->make;
my $BAR = BAR->make;

sub try {
	my ($x, $y, $z, $t) = getargs(@_, qw(x=i y=ARRAY z t=FOO));
	return ($x, $y, $z, $t);
}

sub tryw {
	my ($x, $y, $z, $t) = getargs(@_, [qw(x=i y=ARRAY z t=FOO)]);
	return ($x, $y, $z, $t);
}

my ($x, $y, $z, $t);

eval { try(-x => -2, -t => $FOO, -Other => 1, -y => [], -z => undef) };
like($@,qr/switch: -Other\b/);

eval { try(-x => -2, -t => $FOO, -Y => [], -z => undef) };
like($@,qr/\bargument 'y' missing\b/);

($x, $y, $z, $t) = try(-x => -2, -t => $FOO, -y => [qw(A C)], -z => undef);
is($x,-2);
is(ref $y eq 'ARRAY' && $y->[1] eq 'C',1);
ok(!defined $z);
is(ref $t,'FOO');

eval { tryw(-x => -2, -t => $FOO, -Other => 1, -y => [], -z => undef) };
like($@,qr/switch: -Other\b/);

eval { tryw(-x => -2, -t => $FOO, -Y => [], -z => undef) };
like($@,qr/switch: -Y\b/);

($x, $y, $z, $t) = tryw(-t => $FOO, -z => []);
ok(!defined $x);
ok(!defined $y);
is(ref $z,'ARRAY');
is(ref $t,ref $FOO);

