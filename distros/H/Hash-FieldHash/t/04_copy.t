#!perl -w

use strict;
use Test::More tests => 12;

#use Hash::Util::FieldHash::Compat qw(:all);
use Hash::FieldHash qw(:all);

fieldhashes \my(%a, %b, %c);

{
	my $o = {};
	my $p = {};
	$a{$o} = 42;
	$a{$p} = 3.14;
	%b = %a;

	is_deeply [sort values %a], [sort 42, 3.14];
	is_deeply [sort values %b], [sort 42, 3.14];

	$a{$o}++;
	is_deeply [sort values %a], [sort 43, 3.14];
	is_deeply [sort values %b], [sort 42, 3.14];

	%b = %a;
	is_deeply [sort values %a], [sort 43, 3.14];
	is_deeply [sort values %b], [sort 43, 3.14];

	%c = %b;
	is_deeply [sort values %c], [sort 43, 3.14];

	%c = ();
	is_deeply [sort values %a], [sort 43, 3.14];
	is_deeply [sort values %b], [sort 43, 3.14];
	is_deeply \%c, {};
}

is_deeply \%a, {};
is_deeply \%b, {};

