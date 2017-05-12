#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);

use Encode;

BEGIN {
	use_ok qw(IO::Easy);
	use_ok qw(IO::Easy::File);
	use_ok qw(IO::Easy::Dir);
};

my $path = 't/a';

my $t = IO::Easy->new ('t');

my $io  = $t->append ('a')->as_dir;
my $io2 = $t->dir_io ('a');

ok $io eq $io2;

$io->rm_tree
	if -d $io;

ok (! -e $io);

$io->create;

ok (-d $io);

my $file = $io->append ('b')->as_file;

my $file2 = $io->file_io ('b');

ok $file eq $file2;

$file->touch;

$io->dir_io ('x')->create;
$io->file_io ('x', 'y')->touch;
$io->dir_io ('z')->create;

my @scanned;

$io->scan_tree (sub {
	my $f = shift;
	push @scanned, $f->rel_path ($io);
	return 0 if $f->name eq 'x';
});

ok @scanned == 3;
ok scalar (grep {/^(?:b|x|z)$/} @scanned) == 3;

@scanned = ();

$io->scan_tree (sub {
	my $f = shift;
	push @scanned, $f->rel_path ($io);
});

ok @scanned == 4;
ok scalar (grep {/^(?:b|x|x.y|z)$/} @scanned) == 4;

@scanned = ();

$io->scan_tree (for_files_only => sub {
	my $f = shift;
	push @scanned, $f->rel_path ($io);
});

ok @scanned == 2;
ok scalar (grep {/^(?:b|x.y)$/} @scanned) == 2;

@scanned = ();

$io->scan_tree (ignoring_return => sub {
	my $f = shift;
	push @scanned, $f->rel_path ($io);
	return 0 if $f->name eq 'x';
});

ok @scanned == 4;
ok scalar (grep {/^(?:b|x|x.y|z)$/} @scanned) == 4;

my @files = $io->items;

ok scalar grep {$file->path eq $_->path} @files;

$io->rm_tree;
