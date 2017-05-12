#!/usr/bin/perl -w

# A BASIC interpreter.
#
# Reads in file $ARGV[0] or "program.bas" by default and runs it as a BASIC
# program.
use strict;
use Language::Basic;

my $Default_Filename = "program.bas";
die "Usage: $0 [filename] - runs BASIC program filename\nRuns $Default_Filename by default\n" unless -e "$Default_Filename" or @ARGV;

my $Program = new Language::Basic::Program;
my $infile = shift || "$Default_Filename";

# Read the lines from a file
print("Reading program... \n");
$Program->input($infile);

# Parse the lines
print ("Parsing program... \n");
$Program->parse;

# Implement the program
print("Beginning to run the program...\n\n");
$Program->implement;

print "\n\nDone running the program.\n";
exit(0);
