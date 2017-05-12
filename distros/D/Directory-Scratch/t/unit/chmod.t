#!/usr/bin/env perl

use Test::More tests => 7;
use Directory::Scratch;
use strict;
use warnings;

my $tmp = Directory::Scratch->new;
ok $tmp, 'created $tmp' ;

my @files = qw/foo bar baz/;
my @paths = map { $tmp->touch($_, "this is $_") } @files;
is scalar @paths, 3, '3 files created';

$tmp->chmod(0666, @files);
is mode($_), 0666, 'mode is 0666' for @paths;

$tmp->chmod(0444, 'foo');
is mode($paths[0]), 0444, 'mode is 0444 for foo';
is mode($paths[1]), 0666, 'mode is 0666 for bar';

sub mode {
    my $mode = [stat $_[0]]->[2];
    $mode &= 0777;
    return $mode;
}
