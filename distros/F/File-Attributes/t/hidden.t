#!/usr/bin/perl
# hidden.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

# test that simple attributes work on hidden (UNIX) files

use Test::More tests => 4;
use File::Attributes::Simple;
use Directory::Scratch;

my $temp = Directory::Scratch->new;
my $FILE = $temp->touch('file');
my $DIR  = $temp->mkdir('dir');

ok(-e $FILE);
ok(-d $DIR);

my $simple = File::Attributes::Simple->new;

$simple->set($FILE, 'foo', 'bar');
$simple->set($DIR,  'foo', 'bar');

is($simple->get($FILE, 'foo'), 'bar');
is($simple->get($DIR,  'foo'), 'bar');
