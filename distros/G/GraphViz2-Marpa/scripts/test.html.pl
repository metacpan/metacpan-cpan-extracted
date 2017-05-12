#!/usr/bin/env perl

use strict;
use warnings;

use GraphViz2::Marpa::Utils;

# -----------

print "Input files containing <<table...>>: 14, 15, 30 .. 35, 38 \n";

my($file_name)     = shift || '14';
my($data_dir_name) = 'data';
my($in_suffix)     = 'gv';
my($utils)         = GraphViz2::Marpa::Utils -> new;
my($diff)          = $utils -> perform_1_test($file_name);
my($diff_count)    = 0;

my($message);

$diff -> Base(1); # Return line numbers, not indices.

while ($diff -> Next() )
{
	next if ($diff -> Same);

	$diff_count++;

	my($sep) = '';

	if(! $diff -> Items(2) )
	{
		print sprintf "%d,%dd%d\n", $diff -> Get(qw(Min1 Max1 Max2) );
	}
	elsif (! $diff -> Items(1) )
	{
		print sprintf "%da%d,%d\n", $diff -> Get(qw(Max1 Min2 Max2) );
	}
	else
	{
		$sep = "---\n";

		print sprintf "%d,%dc%d,%d\n", $diff -> Get(qw(Min1 Max1 Min2 Max2) );
	}

	print sprintf "< $_" for $diff -> Items(1);
	print sprintf "$sep";
	print sprintf "> $_" for $diff -> Items(2);
	print "\n";
}

print "File: data/$file_name.gv. Diff count: $diff_count. \n";
