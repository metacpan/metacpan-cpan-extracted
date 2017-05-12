#!/usr/bin/perl
# append.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
use Test::More tests => 6;
use Directory::Scratch;
use strict;
use warnings;

my $tmp = Directory::Scratch->new;
ok($tmp, 'created $tmp');
# this tests touch a bit too, sorry.
ok($tmp->touch('foo', qw(Foo bar baz quux)), 'created foo');
my @lines = $tmp->read('foo');
is(scalar @lines, 4, 'read 4 lines');
is_deeply(\@lines, [qw(Foo bar baz quux)]);

$tmp->append('foo', qw(Now the lines are different));
@lines = $tmp->read('foo');
is(scalar @lines, 9, 'read all 9 lines');
is_deeply(\@lines, [qw(Foo bar baz quux Now the lines are different)]);
