package main;

use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    eval {
	require ExtUtils::Manifest;
	1;
    } or do {
	plan skip_all => 'Can not load ExtUtils::Manifest';
	exit;
    };
}

my @got = ExtUtils::Manifest->manicheck();
ok @got == 0, 'Missing files per MANIFEST';

@got = ExtUtils::Manifest->filecheck();
ok @got == 0, 'Files not in MANIFEST or MANIFEST.SKIP';

done_testing;

1;
