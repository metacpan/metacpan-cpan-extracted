#!/usr/bin/perl
# cleanup.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 8;
use Directory::Scratch;
use strict;
use warnings;

my $tmp = Directory::Scratch->new;
ok($tmp, 'create $tmp');
ok($tmp->touch('foo'), 'touch foo');
ok($tmp->mkdir('bar'), 'mkdir bar');
ok($tmp->touch('bar/baz'), 'touch baz');
$tmp->cleanup;
ok(!$tmp->exists('foo'));
ok(!$tmp->exists('bar'));
ok(!$tmp->exists('baz'));
ok(!-e $tmp->base, 'no base');

