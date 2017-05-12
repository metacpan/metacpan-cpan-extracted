#!/usr/bin/perl -w

# A BASIC interpreter.
#
# Reads in file $ARGV[0] or "program.bas" by default and runs it as a BASIC
# program.
use strict;
use Language::Basic;

my $Default_Filename = "program.bas";
die "Usage: $0 [filename] - translates BASIC program filename into Perl\n$Default_Filename by default\n" unless -e "$Default_Filename" or @ARGV;

my $Program = new Language::Basic::Program;
my $infile = shift || "$Default_Filename";

# Read the lines from a file
warn("Reading program... \n");
$Program->input($infile);

# Parse the lines
warn ("Parsing program... \n");
$Program->parse;

# Implement the program
warn("Beginning to output the program as perl...\n");
$Program->output_perl;

warn "Done translating the program.\n";
exit(0);
