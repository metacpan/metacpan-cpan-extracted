#!/usr/bin/perl
# test-works.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

# make sure the ::Test module works
use Test::More tests => 12;
use FindBin qw($Bin);
use File::Spec;
use lib File::Spec->catfile($Bin, 'lib');
use File::Attributes::Test;
use strict;
use warnings;
use Directory::Scratch;

my  $tmp = Directory::Scratch->new;
my $FILE = $tmp->touch('file');

ok(-e $FILE);

my $test = File::Attributes::Test->new;
ok($test->isa('File::Attributes::Test'));
ok($test->applicable($FILE), "$FILE is applicable");

my @attrs = $test->list($FILE);
is_deeply([@attrs], [], 'clean start');

$test->set($FILE, 'foo', 'bar');
is($test->get($FILE, 'foo'), 'bar', 'setting foo worked');

$test->set($FILE, 'baz', 'quux');
is($test->get($FILE, 'baz'), 'quux', 'setting baz worked');
is($test->get($FILE, 'foo'), 'bar',  'foo was not forgotten'); 

@attrs = sort $test->list($FILE);
is_deeply(\@attrs, [qw|baz foo|], 'listing works');

$test->unset($FILE, 'foo');
@attrs = sort $test->list($FILE);
is_deeply(\@attrs, [qw|baz|], 'unset works');

$test->unset($FILE, 'baz');
@attrs = sort $test->list($FILE);
is_deeply(\@attrs, []);

$test->set($FILE, fooNONONO => 'bar');
is($test->get($FILE, 'foo'), undef, 'fooNONONO ignored');

my $nonono = $tmp->touch('NONONO');
ok(!$test->applicable($nonono), 'file named NONONO is not applicable');
