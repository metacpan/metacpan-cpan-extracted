#!/usr/bin/perl
# simple-cleanup.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 6;
use File::Attributes::Simple;

use Directory::Scratch;

my  $tmp = Directory::Scratch->new;
my $FILE = $tmp->touch('file');

ok(-e $FILE);

my $simple = File::Attributes::Simple->new;
ok($simple->isa('File::Attributes::Simple'));


$simple->set($FILE, 'foo' => 'bar');
ok($tmp->exists('.file.attributes'), 'created attributes file');
$simple->set($FILE, 'bar' => 'baz');
ok($tmp->exists('.file.attributes'), 'attributes file still exists');
$simple->unset($FILE, 'foo');
ok($tmp->exists('.file.attributes'), 'attributes file still exists');
$simple->unset($FILE, 'bar');
ok(!$tmp->exists('.file.attributes'), 'attributes file gone');
