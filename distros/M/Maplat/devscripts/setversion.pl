#!/usr/bin/perl

# MAPLAT  (C) 2008-2010 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

use strict;
use warnings;

my $newversion = shift @ARGV || "???";

if($newversion eq "???") {
	print "Usage: perl devscripts/setversion.pl 9.87\n";
	exit(0);
}

print "Searching files...\n";
my @files = find_pm('lib');

print "Changing files:\n";
foreach my $file (@files) {
	print "Editing $file...\n";

	my @lines;
	open(my $ifh, "<", $file) or die($!);
	@lines = <$ifh>;
	close $ifh;

	open(my $ofh, ">", $file) or die($!);
	foreach my $line (@lines) {
		$line =~ s/VERSION = .*\;/VERSION = $newversion;/g;
		print $ofh $line;
	}
	close $ofh;
}
print "Done.\n";
exit(0);



sub find_pm {
	my ($workDir) = @_;

	my @files;
	opendir(my $dfh, $workDir) or die($!);
	while((my $fname = readdir($dfh))) {
		next if($fname eq "." || $fname eq ".." || $fname eq ".hg");
		$fname = $workDir . "/" . $fname;
		if(-d $fname) {
			push @files, find_pm($fname);
		} elsif($fname =~ /\.pm$/i && -f $fname) {
			push @files, $fname;
		}
	}
	closedir($dfh);
	return @files;
}
