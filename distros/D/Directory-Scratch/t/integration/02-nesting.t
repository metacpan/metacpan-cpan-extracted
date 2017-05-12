#!/usr/bin/perl
# 02-nesting.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

# make sure nesting directories is ok
use Test::More tests => 4;
use Directory::Scratch;

my $tmp = Directory::Scratch->new;

my $a = $tmp->mkdir('a');
ok(-d $a);
my $b = $tmp->mkdir('a/b');
ok(-d $a);
ok(-d $b);

my $c = $tmp->mkdir('foo/bar/baz');
ok(-d $c);
