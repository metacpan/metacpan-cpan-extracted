#!/usr/bin/perl
# 05-readwrite.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Directory::Scratch;
use Test::More tests=>15;
use strict;
use warnings;

my $t = Directory::Scratch->new;
ok($t->touch('foo'));
is($t->read('foo'), q{}, "nothing in foo");
ok($t->write('foo', "this is a test"));
is(scalar $t->read('foo'), "this is a test", 'read test');
is_deeply([$t->read('foo')], ["this is a test"]);

ok($t->touch('bar', qw(this is a test)));
is(scalar $t->read('bar'), "this\nis\na\ntest");
is_deeply([$t->read('bar')], [qw(this is a test)]);

ok($t->touch('baz', "this already has a line"));
ok($t->write('baz', "oh no, it went away"));
is(scalar $t->read('baz'), "oh no, it went away");
ok($t->write('baz', qw(foo bar baz yay!)));
is(scalar $t->read('baz'), "foo\nbar\nbaz\nyay!");
is_deeply([$t->read('baz')], [qw(foo bar baz yay!)]);

eval {
    $t->write('/made/up/filename', qw(foo bar));
};
ok(!$@, "didn't get an error");
