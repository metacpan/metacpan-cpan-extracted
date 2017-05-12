#!/usr/bin/perl
# delete.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 17;
use Directory::Scratch;
use strict;
use warnings;

my $tmp = Directory::Scratch->new;
ok($tmp, '1 ko'); # palindromic > informative 
ok($tmp->touch('foo'), 'touch foo');
ok($tmp->mkdir('bar'), 'mkdir bar');
ok($tmp->touch('bar/baz'), 'touch bar/baz');

ok( $tmp->exists('bar/baz'), 'bar/baz exists');
ok( $tmp->delete('bar/baz'), 'delete bar/baz');
ok(!$tmp->exists('bar/baz'), 'bar/baz !exists');

ok( $tmp->exists('bar'), 'bar exists');
ok( $tmp->delete('bar'), 'rmdir bar');
ok(!$tmp->exists('bar'), 'bar !exists');

ok( $tmp->exists('foo'), 'foo exists');
ok( $tmp->delete('foo'), 'delete foo');
ok(!$tmp->exists('foo'), 'foo !exists');

ok($tmp->mkdir('bar'), 'create bar again');
ok($tmp->touch('bar/baz'), 'create bar/baz again');
ok($tmp->exists('bar/baz'), 'bar/baz exists');
eval {
    $tmp->delete('bar');
};
ok($@, q{can't remove full directory});
