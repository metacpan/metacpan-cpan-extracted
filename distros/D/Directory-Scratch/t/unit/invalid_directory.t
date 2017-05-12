#!/usr/bin/perl
# invalid_directory.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 7;
use Directory::Scratch;
use strict;
use warnings;

my $tmp = Directory::Scratch->new;
my $d;

ok($tmp->touch('foo'), 'create a file called foo');

$d = eval {
    $tmp->mkdir('foo');
};
ok(!$d, 'no directory');
ok($@, "can't create a directory with the same name as a file: $@");

undef $d;
$d = eval {
    no warnings 'redefine';
    # mostly here to make devel::cover happy; the above is the real test
    *Path::Class::Dir::mkpath = sub { mkdir $tmp->exists('foo') };
    $tmp->mkdir('foo');
};
ok(!$d, 'no directory');
ok($@, "can't create a directory with the same name as a file: $@");

undef $d;
$d = eval {
    # make mkdir not work
    no warnings 'redefine';
    *Path::Class::Dir::mkpath = sub { return };
    $tmp->mkdir('bar');
};
ok(!$d, 'no directory');
ok($@, "can't create a directory when mkdir doesn't work: $@");
