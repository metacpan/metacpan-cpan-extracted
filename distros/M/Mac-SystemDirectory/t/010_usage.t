#!perl -w

use strict;

use Test::More tests => 9;

BEGIN {
    use_ok('Mac::SystemDirectory', qw(FindDirectory HomeDirectory TemporaryDirectory));
}

eval { FindDirectory() };
like($@, qr/^Usage: /, 'FindDirectory() without arguments throws an usage exception');

eval { FindDirectory(0, 0, 0) };
like($@, qr/^Usage: /, 'FindDirectory() with to may arguments throws an usage exception');

eval { FindDirectory(0) };
is($@, '', 'FindDirectory(0) lives');

eval { FindDirectory(0, 0) };
is($@, '', 'FindDirectory(0, 0) lives');

eval { HomeDirectory(0) };
like($@, qr/^Usage: /, 'HomeDirectory() with arguments throws an usage exception');

eval { HomeDirectory() };
is($@, '', 'HomeDirectory() lives');

eval { TemporaryDirectory(0) };
like($@, qr/^Usage: /, 'TemporaryDirectory() with arguments throws an usage exception');

eval { TemporaryDirectory() };
is($@, '', 'HomeDirectory() lives');

