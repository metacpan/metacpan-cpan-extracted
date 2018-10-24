#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 11;

use JSON::Patch 'patch';

eval { patch([], undef) };
like($@, qr/^Arrayref expected for patch /);

eval { patch([], [undef]) };
like($@, qr/^Hashref expected for patch item /);

eval { patch([], [{}]) };
like($@, qr/^Undefined op value /);

eval { patch([], [{'op' => 'add'}]) };
like($@, qr/^Path parameter missing /);

eval { patch([], [{'op' => 'add', 'path' => 'garbage'}]) };
like($@, qr/^Failed to parse 'path' pointer /);

eval { patch([], [{'op' => 'add', 'path' => '/0'}]) };
like($@, qr/^Value parameter missing /);

eval { patch([], [{'op' => 'remove', 'path' => '/0'}]) };
like($@, qr/^Path does not exist /);

eval { patch([], [{'op' => 'test', 'path' => '/oops', 'value' => undef}]) };
like($@, qr/^Path does not exist /);

eval { patch([ 0 ], [{'op' => 'copy', 'path' => '/0'}]) };
like($@, qr/^Failed to parse 'from' pointer /);

eval { patch([ 0 ], [{'op' => 'move', 'from' => '/foo', 'path' => '/0'}]) };
like($@, qr/^Source path does not exist /);

eval { patch([], [{'op' => 'garbage', path => '/foo'}]) };
like($@, qr/^Unsupported op 'garbage' /);

