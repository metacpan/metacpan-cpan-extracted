#!/usr/bin/perl
# 04-links.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Directory::Scratch;
use Test::More;
use strict;
use warnings;
plan skip_all => "links don't work under Win32" if $^O eq 'MSWin32';
plan tests => 14;

my $t = Directory::Scratch->new;
my $file1 = $t->touch('test', "this is a test");
my $dir   = $t->mkdir('foo');
my $file2 = $t->touch('foo/test', "this is also a test");

ok($file1);
ok($dir);
ok($file2);

ok($t->link('test', 'new_test'));
ok($t->link('foo', 'new_foo'));
ok($t->link('foo/test', 'new_foo_test'));
ok($t->link('new_foo/test', 'newer_test'));

is($t->read('test'), "this is a test");

is($t->read('foo/test'), "this is also a test");
is($t->read('newer_test'), "this is also a test");
is($t->read('new_foo/test'), "this is also a test");

ok($t->touch('bar'));
eval {
    $t->link('test', 'bar');
};
ok($@, 'cannot link over an existing file');

eval {
    $t->link('test', 'test');
};
ok($@, 'cannot link over self');
