#!/usr/bin/perl -w

use lib 't/lib';
use warnings;
use strict;

use Wolfcastle;
use Test::More tests => 9;
use Test::Exception;
use Data::Dumper;
use Try::Tiny;

try {
	my $api = Wolfcastle->new;

	is($api->call('GET:/status'), 'ALL IS WELL', 'status ok');
	is($api->call('GET:/math/sum', { one => 1, two => 2 }), 3, 'sum from params ok');
	is($api->call('GET:/math/diff', { one => 3, two => 1 }), 5, 'diff ok');
	dies_ok { $api->call('GET:/math/factorial', { num => 5 }) } 'factorial dies ok when bad method';
	is($api->call('POST:/math/factorial', { num => 0 }), 1, 'factorial zero ok');
	is($api->call('POST:/math/factorial', { num => 5 }), 120, 'factorial non-zero ok');
	dies_ok { $api->call('GET:/math/sum', { one => 'a', two => 2 }) } 'bad param ok';
	dies_ok { $api->call('GET:/math/asdf', { one => 1, two => 2 }) } 'wrong method ok';
	dies_ok { $api->call('GET:/nath/sum', { one => 1, two => 2 }) } 'wrong topic ok';
} catch {
	diag(Dumper($_));
};

done_testing();
