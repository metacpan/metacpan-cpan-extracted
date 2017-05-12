#!/usr/bin/perl
# 01-parents_too.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 2;
use Directory::Scratch;
use strict;
use warnings;

my $t = Directory::Scratch->new;

ok($t->touch('foo/bar/baz/bat/yay', qw(foo bar baz bat yay)));
is_deeply([$t->read('foo/bar/baz/bat/yay')], [qw(foo bar baz bat yay)]);
