#!/usr/bin/perl
# ls.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 12;
use Directory::Scratch;
use strict;
use warnings;
use Path::Class;

my $tmp = Directory::Scratch->new;
ok($tmp, 'created $tmp');

ok($tmp->touch('foo'), 'foo');
ok($tmp->mkdir('bar/baz'), 'bar/baz');
ok($tmp->touch('bar/quux'), 'bar/quux');
ok($tmp->touch('bar/baz/quux'), 'bar/baz/quux');

my @files = sort $tmp->ls;
is(scalar @files, 5, 'got 5 files under /');
my @reference = (file('bar'), dir(qw|bar baz|), file(qw|bar baz quux|),
		 file(qw|bar quux|), file('foo'));
is_deeply([map {$_->stringify} @files],
	  [map {$_->stringify} @reference],
	  'check that paths agree');

# test ls /
@files = sort $tmp->ls('/');
is(scalar @files, 5, 'got 5 files under /');
@reference = (file('bar'), dir(qw|bar baz|), file(qw|bar baz quux|),
	     file(qw|bar quux|), file('foo'));
is_deeply([map {$_->stringify} @files],
	  [map {$_->stringify} @reference],
	  'check that paths agree');

eval {
    @files = sort $tmp->ls('this filename is fake');
};
ok($@, "can't ls files that don't exist");

@files = sort $tmp->ls('foo');
is_deeply(\@files, [file('foo')], 'single file = list');

@files = sort $tmp->ls('bar/baz');
is_deeply(\@files, [file(qw|bar baz quux|)], 'got bar/baz/quux in bar/baz');
