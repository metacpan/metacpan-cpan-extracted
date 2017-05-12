#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw{no_plan};

use File::Fu;

my $dir = File::Fu->dir('foo/bar/baz/bort/');
is($dir->slice(0,3), 'foo/bar/baz/bort/');
is($dir->slice(0,-1), 'foo/bar/baz/bort/');
is($dir->slice(0,-2), 'foo/bar/baz/');
is($dir->slice(0,-3), 'foo/bar/');
is($dir->slice(-2,-1), 'baz/bort/');


# vim:ts=2:sw=2:et:sta
