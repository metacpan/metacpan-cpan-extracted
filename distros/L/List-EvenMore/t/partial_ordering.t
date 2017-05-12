#!/usr/bin/perl -w -I../lib

use List::EvenMoreUtils qw(partial_ordering_differs);

use Test::More tests => 7;

my $ret;

$ret = partial_ordering_differs(
	'first' => [qw(one two three four five six)],
	'second' => [qw(seven eight nine)],
	'third' => []
);

is($ret, undef, 'no elements in common');

$ret = partial_ordering_differs(
	'first' => [qw(one two three four five six seven)],
	'second' => [qw(seven eight nine)],
	'third' => []
);

is($ret, undef, 'just one element in common');

$ret = partial_ordering_differs(
	'first' => [qw(one two three four five six seven nine)],
	'second' => [qw(seven eight nine)],
	'third' => []
);

is($ret, undef, 'just two elements in common');


$ret = partial_ordering_differs(
	'first' => [qw(one two three four five six seven nine)],
	'second' => [qw(two seven eight nine)],
	'third' => []
);

is($ret, undef, 'three elements in common');


$ret = partial_ordering_differs(
	'first' => [qw(one two three four five six seven nine)],
	'second' => [qw(two five seven eight nine)],
	'third' => []
);

is($ret, undef, 'three elements in common');

$ret = partial_ordering_differs(
	'first' => [qw(one two three four five six seven nine)],
	'second' => [qw(two five seven eight nine)],
	'third' => []
);

is($ret, undef, 'four elements in common');


$ret = partial_ordering_differs(
	'first' => [qw(one two three four five six seven nine)],
	'second' => [qw(five two seven eight nine)],
	'third' => []
);

like($ret, qr/five|two/, 'ordering mistake');


