#!perl -w

use strict;

use Test::More tests => 3;

BEGIN {
    use_ok('Mac::SystemDirectory', qw[FindDirectory NSApplicationDirectory HomeDirectory]);
}

ok(defined(FindDirectory(NSApplicationDirectory)), 'FindDirectory(NSApplicationDirectory) returned a defined value');
ok(defined(HomeDirectory()), 'HomeDirectory() returned a defined value');
