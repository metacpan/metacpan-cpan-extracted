#!/usr/bin/perl
# 01-attributes.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 19;
use Directory::Scratch;
use File::Attributes qw(set_attribute get_attribute);
use File::Attributes::Recursive qw(:all);

my $tmp = Directory::Scratch->new;
my $top = $tmp->base;
my $a = $tmp->mkdir('a');
my $b = $tmp->mkdir('a/b');
my $c = $tmp->mkdir('a/b/c');
my $d = $tmp->touch('a/b/c/d');
ok(-e $d, 'files created OK');

set_attribute($a, 'a' => 'yes');
set_attribute($b, 'b' => 'yes');
set_attribute($c, 'c' => 'yes');
set_attribute($d, 'd' => 'yes');

# make sure File::Attributes is working
map {eval "is(get_attribute(\$$_, '$_') => 'yes');"} qw(a b c d);

is(get_attribute_recursively($d, 'a')     => 'yes', 'works limitlessly');
is(get_attribute_recursively($d, $b, 'a') => undef, 'limit works');
is(get_attribute_recursively($d, $a, 'a') => 'yes', 'limit stops properly');

is_deeply([sort (list_attributes_recursively($d, $a))] => [qw|a b c d|]); 
is_deeply([sort (list_attributes_recursively($d, $b))] => [qw|b c d|]); 

my %attributes = get_attributes_recursively($d, $a);

is($attributes{a} => 'yes');
is($attributes{b} => 'yes');
is($attributes{c} => 'yes');
is($attributes{d} => 'yes');

set_attribute($c, a => 'no way, jose');

%attributes = get_attributes_recursively($d, $a);
is($attributes{a} => 'no way, jose');
is($attributes{b} => 'yes');
is($attributes{c} => 'yes');
is($attributes{d} => 'yes');

is_deeply([sort (list_attributes_recursively($d, $a))] => [qw|a b c d|]); 
