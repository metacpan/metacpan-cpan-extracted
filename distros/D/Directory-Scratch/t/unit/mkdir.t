#!/usr/bin/perl
# mkdir.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 9;
use Directory::Scratch;
use strict;
use warnings;

my $tmp = Directory::Scratch->new;
ok($tmp, 'created $tmp');

my $dir = $tmp->mkdir('foo/bar/baz/bat');
for(1..4){
    ok(-e $dir, "$dir exists");
    ok(-d $dir, '  and is a directory');
    $dir = $dir->parent;
}
