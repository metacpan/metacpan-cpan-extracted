#!/usr/bin/perl
# 03-list.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests=>16;
use Directory::Scratch;
use Path::Class;

my @files = qw(foo bar baz);
my @dirs  = qw(1 2 3);

my $t = Directory::Scratch->new;
my @list;

foreach my $dir (@dirs){
    my $tmp = $t->mkdir($dir);
    ok($tmp, "mkdir $dir");
    push @list, $dir;
    foreach my $file (@files){
	my $name = file($dir, $file);
	$tmp = $t->touch($name); 
	ok($tmp, "touch $tmp");
	push @list, $name;
    }
}

# do it
my @result = $t->ls;

@list   = sort @list;
@result = sort @result;

is_deeply(\@result, \@list, "listed everything");

@result = $t->ls;
@result = sort @result;
is_deeply(\@result, \@list, "listed everything (with /)");

@result = sort $t->ls('1');

my @possible = map {file('1', $_)} qw(bar baz foo);

is_deeply(\@result, \@possible, 'listed 1');

$t->touch('fooo');
is_deeply([$t->ls('fooo')], ['fooo'], "listing a single file is OK");

