#!/usr/bin/perl -w

use strict;
use Test::More;
use File::Find::Duplicates;

BEGIN {
	eval "require File::Temp";
	plan $@
		? (skip_all => 'need File::Temp for testing')
		: (tests => 4);
}

File::Temp->import(qw/tempfile tempdir/);
my $A = "A" x 10000 . "\n";
my $B = "B" x 100 . "\n";
my $C = "C" x 100 . "\n";
my $D = "D" x 100 . "\n";

my $dir1 = tempdir(CLEANUP => 1);
my $dir2 = tempdir(CLEANUP => 1);

my $writeit = sub { 
	my $text = shift;
	my $dir = shift || $dir1;
	my ($fh, $fname) = tempfile(DIR => $dir);
	print $fh $text;
	close $fh;
	return $fname;
};

my %filename = (
	$writeit->($A) => "A",
	$writeit->($A) => "A",
	$writeit->($A, $dir2) => "A",
	$writeit->($B) => "B",
	$writeit->($B) => "B",
	$writeit->($C) => "C",
	$writeit->($C) => "C",
	$writeit->($D) => "D",
);

my @dupes = find_duplicate_files($dir1, $dir2);

is @dupes, 3, "3 sets of duplicates";

foreach my $set (@dupes) { 
	my @files = map $filename{$_}, @{$set->files};
	is grep($_ ne $files[0], @files), 0, "All $files[0] files found";
}

__END__

my %dupe_count;
foreach my $filesize (sort keys %dupes) {
	$dupe_count{ scalar @{ $dupes{$filesize} } }++;
}

is $dupe_count(3), 1, "DC3";
is $dupe_count(2), 1, "DC2";

