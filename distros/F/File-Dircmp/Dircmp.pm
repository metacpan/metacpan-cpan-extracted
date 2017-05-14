# Copyright (c) 2003 Josh Schulte. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

package File::Dircmp;

require Exporter;

@ISA = "Exporter";
@EXPORT = qw(dircmp);

use File::Basename;
use File::Compare;
use File::Glob "bsd_glob";
use strict;

my @g_diffs;
my $g_d = 0;
my $g_s = 0;
 
#
# TODO: implement switch to compare the contents of files with the same
# name in both directories and output a list telling what must be changed
# in the two files to bring them into agreement.
#

############################## dircmp() ##############################
#
# print directory differences
#
# arguments:
# first directory
# second directory
# 1 to show file diffs
# 1 to suppress messages about identical files
#
# return:
# list of differences
#
sub dircmp
{
	my $d1 = shift;
	my $d2 = shift;
	my $dodiff = shift;
	my $suppress = shift;

	# need to reset global vars every time called
	@g_diffs = ();
	$g_d = 0;
	$g_s = 0;

	$g_d = 1 if $dodiff;
	$g_s = 1 if $suppress;
	
	unless( -d $d1)
	{
		push(@g_diffs, "$d1 not a directory !");
		return @g_diffs;
	}

    unless( -d $d2)
    {
        push(@g_diffs, "$d2 not a directory !");
        return @g_diffs;
    }

	compare_dirs($d1, $d2);
	
	return @g_diffs;
}

sub compare_dirs
{
	# get args
	my $d1 = shift;
	my $d2 = shift;

	# find out what files are in directories
	my %d1_files;
	my %d2_files;
	
	$d1_files{basename($_)} = 0 foreach bsd_glob("$d1/.*");
	$d1_files{basename($_)} = 0 foreach bsd_glob("$d1/*");
		
	delete $d1_files{"."};
	delete $d1_files{".."};

	$d2_files{basename($_)} = 0 foreach bsd_glob("$d2/.*");
	$d2_files{basename($_)} = 0 foreach bsd_glob("$d2/*");
		
	delete $d2_files{"."};
	delete $d2_files{".."};

	# find out what is common and exclusive to each directory
	my %common;
	my @d1_only;
	my @d2_only;
	
	foreach my $x (keys(%d1_files))
	{
		if(defined $d2_files{$x})
		{
			$common{$x} = 0;
		}
		else
		{
			push(@d1_only, $x);
		}
	}

	foreach my $x (keys(%d2_files))
	{
		push(@d2_only, $x) unless defined $common{$x};
	}

	# add missing files to the list
	push(@g_diffs, "Only in $d1: $_") foreach @d1_only;
	push(@g_diffs, "Only in $d2: $_") foreach @d2_only;

	# compare common files
	foreach my $x (keys %common)
	{
		my $d1_file = "${d1}/${x}";
		my $d2_file = "${d2}/${x}";

		if((-f $d1_file) && (-f $d2_file))
		{
			unless(compare($d1_file, $d2_file))
			{
				unless($g_s)
				{
					push(@g_diffs, "Files $d1_file and $d2_file are identical");
				}
			}
			else
			{
				push(@g_diffs, "Files $d1_file and $d2_file differ");
			}
		}
		elsif((-d $d1_file) && (-d $d2_file))
		{
			compare_dirs($d1_file, $d2_file);
		}
		elsif((-f $d1_file) && (-d $d2_file))
		{
			push(@g_diffs, "File $d1_file is a regular file while file $d2_file is a directory");
		}
		elsif((-d $d1_file) && (-f $d2_file))
		{
			push(@g_diffs, "File $d1_file is a directory while file $d2_file is a regular file");
		}
	}
}

1;

=head1 NAME

dircmp - directory comparison

=head1 SYNOPSIS

use File::Dircmp;

@r = dircmp($dir1, $dir2, $diff, $suppress);

=head1 DESCRIPTION

The dircmp command examines dir1 and dir2 and generates various tabulated information about the contents of the directories. Listings of files that are unique to each directory are generated for all the options. If no option is entered, a list is output indicating whether the file names common to both directories have the same contents. 

The algorithm I use orders the report differently than the unix commands. There is no option to control the length of the output.

=head1 OPERANDS

$dir1   A path name of a directory to be compared.

$dir2   A path name of a directory to be compared.

$diff   Compare the contents of files with the same name in both directories and output a list telling what must be changed in the two files to bring them into agreement. The list format is described in diff(1).

$suppress   Suppress messages about identical files.

=head1 TODO

Implement the $diff argument.

=head1 AUTHOR

Josh Schulte <josh_schulte@yahoo.com>

