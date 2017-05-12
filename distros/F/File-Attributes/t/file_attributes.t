#!/usr/bin/perl
# file_attributes.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 14;
use File::Attributes qw(:all);
use Directory::Scratch;
use strict;
use warnings;

my $temp = Directory::Scratch->new;
my $FILE = $temp->touch('file');

ok(-e $FILE, "made tempfile $FILE");

set_attribute($FILE, 'foo', 'bar');
is(get_attribute($FILE, 'foo'), 'bar', 'setting foo worked');

set_attribute($FILE, 'bar', 'baz');
is(get_attribute($FILE, 'foo'), 'bar', 'foo is still here');
is(get_attribute($FILE, 'bar'), 'baz', 'setting bar worked');

my @attributes = sort (list_attributes($FILE));
is_deeply(\@attributes, [qw|bar foo|], 'list works'); #5

my %attributes = get_attributes($FILE);
is($attributes{foo}, 'bar', 'hash works');
is($attributes{bar}, 'baz', 'hash works'); 
is($attributes{baz}, undef, 'hash doesnt make things up'); #8

unset_attribute($FILE, 'foo');
is(get_attribute($FILE, 'foo'), undef, 'unsetting foo');
unset_attribute($FILE, 'bar');

@attributes = (list_attributes($FILE));
is_deeply([@attributes], [], 'unset worked; empty list returned');

set_attributes($FILE, 
	       foo => 'bar',
	       bar => 'baz',
	       ' ' => 'nothing');

%attributes = get_attributes($FILE);
is($attributes{foo}, 'bar', 'hash set/get works');
is($attributes{bar}, 'baz', 'hash set/get works'); 
is($attributes{' '}, 'nothing', 'hash set/get works'); 

unset_attributes($FILE, 'foo', 'bar', ' ');
%attributes = get_attributes($FILE);
is(scalar keys %attributes, 0, 'deletion worked');
