#!/usr/bin/perl

# Show just the [sections] of the ini file

die "usage: a.out <ini file>"
	unless @ARGV;

($file) = @ARGV;

system("cat $file | egrep -e \"^\\[\"");
