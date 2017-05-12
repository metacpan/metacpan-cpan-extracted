#!/usr/bin/perl
# 06-append-prepend.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
use Directory::Scratch;
use Test::More tests=>8;
use strict;
use warnings;

my $t = Directory::Scratch->new;
ok($t->write('baz', qw(foo bar baz yay!)));
is(scalar $t->read('baz'), "foo\nbar\nbaz\nyay!");
is_deeply([$t->read('baz')], [qw(foo bar baz yay!)]);
ok($t->append('baz', qw(yay! again)));

is(scalar $t->read('baz'), "foo\nbar\nbaz\nyay!\nyay!\nagain");
is_deeply([$t->read('baz')], [qw(foo bar baz yay! yay! again)]);

SKIP: {
    skip "waiting for prepend from uri", 2;
    ok($t->prepend('baz', [qw(what are we gonna do tonight brain)]));
    is_deeply([$t->read('baz')], [qw(what are we gonna do tonight brain foo bar baz yay! yay! again)]);
}
