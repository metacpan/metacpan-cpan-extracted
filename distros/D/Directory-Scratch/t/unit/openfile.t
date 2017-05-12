#!/usr/bin/perl
# openfile.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 8;
use Directory::Scratch;
use Path::Tiny;
use strict;
use warnings;

my $tmp = Directory::Scratch->new;
ok($tmp, 'created $tmp');
my ($fh, $path) = $tmp->openfile('foo');
is($path->stringify, $tmp->exists('foo')->stringify, 
   'openfile returned sane path'); 
eval {
    print {$fh} "Foo\nbar\nbaz\n";
};
ok(!$@, 'writing to fh works');
ok(close $fh, 'closed fh');

$fh = $tmp->openfile('bar');
eval {
    print {$fh} "Foo\nbar\nbaz\n";
};
ok(!$@, 'writing to fh works');
ok(close $fh, 'closed fh');

ok($tmp->exists('bar'), 'bar exists');
my $contents = path($tmp->exists('bar')->stringify)->slurp;
is($contents, "Foo\nbar\nbaz\n", 'bar can be read');

 
