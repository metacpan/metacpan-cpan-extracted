#!/usr/bin/perl
# simple.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 9;
use File::Attributes::Simple;

use Directory::Scratch;

my  $tmp = Directory::Scratch->new;
my $FILE = $tmp->touch('file');

ok(-e $FILE);

my $simple = File::Attributes::Simple->new;
ok($simple->isa('File::Attributes::Simple'));

my @attrs = $simple->list($FILE);
is_deeply([@attrs], [], 'clean start');

$simple->set($FILE, 'foo', 'bar');
is($simple->get($FILE, 'foo'), 'bar', 'setting foo worked');

$simple->set($FILE, 'baz', 'quux');
is($simple->get($FILE, 'baz'), 'quux', 'setting baz worked');
is($simple->get($FILE, 'foo'), 'bar',  'foo was not forgotten'); 

@attrs = sort $simple->list($FILE);
is_deeply(\@attrs, [qw|baz foo|], 'listing works');

$simple->unset($FILE, 'foo');
@attrs = sort $simple->list($FILE);
is_deeply(\@attrs, [qw|baz|], 'unset works');

$simple->unset($FILE, 'baz');
@attrs = sort $simple->list($FILE);
is_deeply(\@attrs, []);


