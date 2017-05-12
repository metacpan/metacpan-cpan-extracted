#!/usr/bin/perl

use Class::Easy;

use Test::More qw(no_plan);

use IO::Easy;

ok file;

ok dir;

ok dir->current->abs_path;

my $test_file = file->new ('test');

$test_file->touch;

ok -f 'test';

ok $test_file->size eq 0;

ok file ('test')->size eq 0;

unlink 'test';

ok ! -f $test_file;

1;

package Test1;

use IO::Easy;

file;