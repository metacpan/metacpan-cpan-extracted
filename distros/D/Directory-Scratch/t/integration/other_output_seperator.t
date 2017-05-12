#!/usr/bin/perl
# other_output_seperator.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 8;
use Directory::Scratch;
use Path::Tiny;

my $tmp = Directory::Scratch->new;

local $, = '!';
local $/ = '!';

ok($tmp->touch('foo', qw(these are some lines)), 'create foo');
my $file = path(''. $tmp->exists('foo'))->slurp;
ok($file, 'read it back in');
is($file, 'these!are!some!lines!', 'lines end in !');

my @file = $tmp->read('foo');
is_deeply(\@file, [qw(these are some lines)], 'works in array context too');

ok($tmp->append('foo', qw(now there are more)), 'add more lines');

$file = path(''. $tmp->exists('foo'))->slurp;
ok($file, 'read it back in');
is($file, 'these!are!some!lines!now!there!are!more!', 'lines end in !');

@file = $tmp->read('foo');
is_deeply(\@file, [qw(these are some lines now there are more)], 
	  'works in array context too');
