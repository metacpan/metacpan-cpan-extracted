#!/usr/bin/perl
# simple.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More;
use File::Attributes::Extended;

use Directory::Scratch;

my  $tmp = Directory::Scratch->new;
my $FILE = $tmp->touch('file');

my $extended = File::Attributes::Extended->new;

plan 'skip_all', "Filesystem doesn't support xattrs" 
  if !$extended->applicable($FILE);
plan tests => 9;

ok($extended->isa('File::Attributes::Extended'));
ok(-e $FILE);

my @attrs = $extended->list($FILE);
is_deeply([@attrs], [], 'clean start');

$extended->set($FILE, 'foo', 'bar');
is($extended->get($FILE, 'foo'), 'bar', 'setting foo worked');

$extended->set($FILE, 'baz', 'quux');
is($extended->get($FILE, 'baz'), 'quux', 'setting baz worked');
is($extended->get($FILE, 'foo'), 'bar',  'foo was not forgotten'); 

@attrs = sort $extended->list($FILE);
is_deeply(\@attrs, [qw|baz foo|], 'listing works');

$extended->unset($FILE, 'foo');
@attrs = sort $extended->list($FILE);
is_deeply(\@attrs, [qw|baz|], 'unset works');

$extended->unset($FILE, 'baz');
@attrs = sort $extended->list($FILE);
is_deeply(\@attrs, []);


