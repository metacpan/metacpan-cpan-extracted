#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
use Directory::Scratch;

my $tmp = Directory::Scratch->new;
my $file = $tmp->touch('foo', 'foo bar baz');

my $stats = $tmp->stat('foo');
isa_ok $stats, 'File::stat', '$stats';

my @stats = $tmp->stat('foo');
ok scalar @stats > 10, 'got an array, not an object';
