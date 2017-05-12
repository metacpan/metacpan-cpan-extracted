#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);

use Encode;

BEGIN {
	use_ok qw(IO::Easy);
	use_ok qw(IO::Easy::File);
	use_ok qw(IO::Easy::Dir);
};

my $io = dir->current->dir_io (qw(t a));

if (-d $io) {
	$io->rm_tree;
}

ok (! -e $io);

$io->create;

ok (-d $io);

my $file = $io->append ('b')->as_file;

$file->touch;

foreach (qw(atime mtime)) { # inode not available in windows
	ok $file->$_, "file $_ is: " . $file->$_;
}

foreach (qw(size)) {
	ok ! $file->$_;
}

$io->rm_tree;
