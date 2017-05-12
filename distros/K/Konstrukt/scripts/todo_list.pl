#!/usr/bin/perl

use strict;
use warnings;

my $filter = '\.(pm|pl|pod|t)$';

unless (@ARGV) {
print <<USAGE;
Scans files for #FIXME, #TODO or #FEATURE lines and creates an overview.

Usage: $0 [options] [files]

Options:
 -bytype: Order list by TODO-type
 -byfile: Order list by filename (default)
 
Files:
 Directories or files that will be scanned recursively

USAGE
exit;
}

my $order;
if ($ARGV[0] eq '-bytype') {
	$order = 'type';
	shift @ARGV;
} elsif ($ARGV[0] eq '-byfile') {
	$order = 'file';
	shift @ARGV;
} else {
	$order = 'file';
}

my @files = &GetFiles($filter);

#collect todos
my $todo_by_file;
my $todo_by_type;
my $count = {FIXME => 0, TODO => 0, FEATURE => 0};
foreach my $file (@files) {
	if (-e $file and -f $file) { #is a file?
		#print "working on file $file\n";
		my @lines = &read_file($file);
		for (my $i = 0; $i < @lines; $i++) {
			if ($lines[$i] =~ /#(FIXME|TODO|FEATURE):?\s*(.*)$/mi) {
				push @{$todo_by_file->{$file}->{uc $1}}, [$2, $i + 1];
				push @{$todo_by_type->{uc $1}->{$file}}, [$2, $i + 1];
				$count->{uc $1}++;
			}
		}
	}
}

#print out list ordered by file
if ($order eq 'type') {
	#print out list ordered by type
	foreach my $type (qw/FIXME TODO FEATURE/) {
		foreach my $file (sort keys %{$todo_by_type->{$type}}) {
			my $prettyfile = $file;
			$prettyfile =~ s/^\.\///;
			print "$prettyfile:\n\n";
			foreach my $entry (@{$todo_by_type->{$type}->{$file}}) {
				print " $type: $entry->[0] (line $entry->[1])\n";
			}
			print "\n";
		}
		print "\n";
	}
} else {
	foreach my $file (sort keys %{$todo_by_file}) {
		my $prettyfile = $file;
		$prettyfile =~ s/^\.\///;
		print "$prettyfile:\n\n";
		foreach my $type (qw/FIXME TODO FEATURE/) {
			foreach my $entry (@{$todo_by_file->{$file}->{$type}}) {
				print " $type: $entry->[0] (line $entry->[1])\n";
			}
		}
		print "\n";
	}
}

print "$count->{FIXME} open FIXMEs, $count->{TODO} open TODOs, $count->{FEATURE} open FEATUREs.\n\n";

sub GetFiles {
	my ($f) = @_;
	$f = ".*?" unless defined $f;
	
	my @files;
	for (@ARGV) {
		push(@files,$_);
	}#for
	#get subdir-contents
	for (my $i = 0; $i < @files; $i++) {
		if (-d $files[$i]) { #dir
			my $cur_dir = $files[$i];
			opendir DIR, $cur_dir;
			my @dir = grep { !/^\.\.?$/ } (readdir DIR);#get files
			@dir = (map "$cur_dir/$_", @dir);
			splice(@files,$i,1,@dir);
			closedir DIR;
			$i--;
		} elsif (-f $files[$i] and not $files[$i] =~ /$f/) {
			#remove file
			splice(@files,$i,1);
			$i--;
		}
	}#for
	return @files;
}

# Description:
#  Returns the content of a given filename as a scalar or list of lines.
sub read_file {
	if (-e $_[0]) {
		open(FILE, $_[0]);
		if (wantarray) {
			my @lines = (<FILE>);
			close FILE;
			return @lines;
		} else {
			local $/ = undef;
			my $file = <FILE>;
			close FILE;
			return $file;
		}
	} else {
		return undef;
	}
}

# Description:
#  Writes given scalars in the passed filename
sub write_file {
	my $filename = shift;
	if (!open(FILE, ">$filename")) {
		return 0;
	}
	print FILE @_;
	close(FILE);
	return 1;
}
#= /$lib->write_file
