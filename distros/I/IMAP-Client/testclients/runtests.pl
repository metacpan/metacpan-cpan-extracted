#!/usr/bin/perl
use strict;

# Get directory listing
my $dirHandle;
opendir($dirHandle,'../t');
my @files = grep { /\d{2}\w+\.t/ } readdir($dirHandle);
close ($dirHandle);

my @runorder = sort(@files);

foreach my $file (@runorder) {
	next if ($file =~ /^.*~$/);
	next if ($file =~ /^\#/);
	print "Running $file...\n";
	`perl -I ../lib/ ../t/$file`;
}
print "Done\n";