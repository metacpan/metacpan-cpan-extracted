#!/usr/bin/perl
# 07-delete.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
use Directory::Scratch;
use Test::More tests=>15;
use strict;
use warnings;

my $t = Directory::Scratch->new;

eval {
    $t->delete('fake');
};
ok($@, "can't delete things that don't exist");

ok($t->mkdir('foo'));
ok($t->touch('foo/bar'));

eval {
    $t->delete('foo');
};
ok($@, "can't delete non-empty directories");

ok($t->exists('foo'));
ok($t->exists('foo/bar'));
ok($t->delete('foo/bar'));
ok($t->delete('foo'));
ok(!$t->exists('foo'));
ok(!$t->exists('foo/bar'));

ok($t->touch('foo'));

SKIP: {
    skip 'no links on win32', 4 if $^O eq 'MSWin32';
    ok($t->link('foo', 'bar'));
    ok($t->exists('bar'));
    ok($t->delete('bar'));
    ok(!$t->exists('bar'));
}
