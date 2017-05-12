#!/usr/bin/perl
# touch.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 8;
use Directory::Scratch;
use strict;
use warnings;
use Path::Tiny;

my $tmp = Directory::Scratch->new;
ok($tmp, 'created $tmp');
ok($tmp->touch('foo', qw(foo bar baz)), 'created foo');
ok($tmp->exists('foo'), 'foo exists');
my @lines = path($tmp->exists('foo')->stringify)->lines;
is(chomp @lines, 3, 'right number of lines');
is_deeply(\@lines, [qw(foo bar baz)], 'foo has correct contents');
ok($tmp->touch('bar'), 'created bar');
ok($tmp->exists('bar'), 'bar exists');
ok(!path($tmp->exists('bar')->stringify)->slurp, 'bar has no content');
