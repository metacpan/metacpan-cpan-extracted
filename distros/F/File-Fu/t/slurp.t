#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use File::Fu;

my $d = File::Fu->dir->temp_dir('tmp.');
my $f = $d + 'file';
is($f->basename, 'file');
my $fh = $f->open('>');
print $fh "foo\nbar\n";
close($fh) or die "cannot write '$f' $!";
ok($f->e);

my @lines = $f->read;
is_deeply(\@lines, ["foo\n", "bar\n"], 'slurp array');
is($f->read, "foo\nbar\n", 'slurp scalar');

# TODO something where File::Slurp is not loaded
# (probably in another test file and messing with @INC)

# vim:ts=2:sw=2:et:sta
