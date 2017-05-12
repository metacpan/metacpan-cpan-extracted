#!/usr/bin/perl
# invalid_clone.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 2;
use Directory::Scratch;
use strict;
use warnings;

eval {
    Directory::Scratch::child({});
};
ok($@, "can't clone an unblessed ref");

eval {
    my $ref = {};
    bless $ref => 'Foo';
    Directory::Scratch::child($ref);
};
ok($@, "can't clone a non-Directory::Scratch ref");

