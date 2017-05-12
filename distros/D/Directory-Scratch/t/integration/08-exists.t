#!/usr/bin/perl
# 08-exists.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Directory::Scratch;
use Test::More tests=>7;
use strict;
use warnings;

my $t    = Directory::Scratch->new;
my $base = $t->base;

ok(!$t->exists('foo/bar'));
ok(!$t->exists('foo'));
ok(!$t->exists('bar'));

my $foobar = $t->touch('foo/bar');
ok($foobar);
is($t->exists('foo/bar'), $foobar);
ok($t->exists('foo'));
ok($t->exists('foo') =~ /foo$/);
