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

my $Is_MSWin32 = $^O eq 'MSWin32';

my $source_dir = tempdir(CLEANUP => true);
my $target_dir = tempdir(CLEANUP => true);

my $sep = sub { [ split /\//, $_[0] ] };

my @dirs = map $sep->($_), (
    $Is_MSWin32 ? () : '.dot',
    'dir/subdir',
);
my @files = map $sep->($_), (
    $Is_MSWin32 ? () : '.dot/.hidden',
    'abc',
    'def',
    'ghi',
    'dir/subdir/jkl',
    'mno',
    'pqr',
);
my %expected = map { File::Spec->catfile($target_dir, @{$sep->($_)}) => true } (
    $Is_MSWin32 ? () : 'sub-.',
    $Is_MSWin32 ? () : 'sub-./.hidden',
    'sub-A',
    'sub-A/abc',
    'sub-D',
    'sub-D/def',
    'sub-G',
    'sub-G/ghi',
    'sub-J',
    'sub-J/jkl',
    'sub-M',
    'sub-M/mno',
    'sub-P',
    'sub-P/pqr',
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

$dir->split_char;

my @got;

File::Find::find({
    wanted => sub { push @got, $File::Find::name; },
}, $target_dir);

shift @got; # remove top-level directory

@got = map { s{/}{\\}g; $_ } @got if $Is_MSWin32;

my %got = map { $_ => true } @got;

is_deeply(\%got, \%expected, 'file tree');
