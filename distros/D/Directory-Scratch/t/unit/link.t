#!/usr/bin/perl
# link.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More;
use Directory::Scratch;
use strict;
use warnings;

plan skip_all => "Win32 can't symlink" if $^O eq 'MSWin32';
plan tests => 4;

my $tmp = Directory::Scratch->new;
ok($tmp, 'created $tmp');
# this tests touch a bit too, sorry.
ok($tmp->touch('foo'), 'created foo');
ok($tmp->link('foo', 'bar'), 'created bar');
ok($tmp->exists('bar'), 'bar exists!');

