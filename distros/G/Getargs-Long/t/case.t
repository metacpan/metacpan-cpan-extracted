#!./perl

use Test::More tests => 9;

require 't/code.pl';

package SENSITIVE;

use Getargs::Long;

sub f {
	my ($x, $X) = getargs(@_, { -strict => 0 }, qw(x X));
	return ($x, $X);
}

package INSENSITIVE;

use Getargs::Long qw(ignorecase);

sub f {
	my ($x, $Y) = getargs(@_, { -strict => 0 }, qw(x Y));
	return ($x, $Y);
}

package OPTION;

use Getargs::Long;

sub f {
	my ($x, $Y) = getargs(@_, { -strict => 0, -ignorecase => 1 }, qw(x Y));
	return ($x, $Y);
}

package main;

my @a;

@a = SENSITIVE::f(-x => 1, -X => 2);
is(@a,2);
is($a[0],1);
is($a[1],2);

@a = INSENSITIVE::f(-x => 1, -y => 2);
is(@a,2);
is($a[0],1);
is($a[1],2);

@a = OPTION::f(-x => 1, -y => 2);
is(@a,2);
is($a[0],1);
is($a[1],2);

