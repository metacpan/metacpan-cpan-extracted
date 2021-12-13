#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true);

use Dir::Split;
use File::Find;
use File::Path;
use File::Spec;
use File::Temp qw(tempdir);
use Test::More tests => 1;

my $source_dir = tempdir(CLEANUP => true);
my $target_dir = tempdir(CLEANUP => true);

my $sep = sub { [ split /\//, $_[0] ] };

my @dirs = map $sep->($_), (
    '.dot',
    'dir/subdir',
);
my @files = map $sep->($_), (
    '.dot/.hidden',
    'abc',
    'def',
    'ghi',
    'dir/subdir/jkl',
    'mno',
    'pqr',
);
my %expected = map { File::Spec->catfile($target_dir, @{$sep->($_)}) => true } (
    'sub-00001',
    'sub-00001/.hidden',
    'sub-00001/abc',
    'sub-00001/def',
    'sub-00001/ghi',
    'sub-00001/jkl',
    'sub-00002',
    'sub-00002/mno',
    'sub-00002/pqr',
);

foreach my $dir (@dirs) {
    mkpath(File::Spec->catfile($source_dir, @$dir));
}
foreach my $file (@files) {
    open(my $fh, '>', File::Spec->catfile($source_dir, @$file));
    close($fh);
}

my $dir = Dir::Split->new(
    source => $source_dir,
    target => $target_dir,
);

$dir->split_num;

my @got;

File::Find::find({
    wanted => sub { push @got, $File::Find::name; },
}, $target_dir);

shift @got; # remove top-level directory

@got = map { s{/}{\\}g; $_ } @got if $^O eq 'MSWin32';

my %got = map { $_ => true } @got;

is_deeply(\%got, \%expected, 'file tree');
