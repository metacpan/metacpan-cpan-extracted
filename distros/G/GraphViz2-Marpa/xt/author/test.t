#!/usr/bin/env perl

use strict;
use warnings;

use GraphViz2::Marpa::Utils;

use Test::More;

# -----------

# Allow for known failures.
# The key '01' means input file data/01.gv, etc.

my(%will_fail) =
(
);

my($count)         = 0;
my($data_dir_name) = 'xt/author/data';
my($in_suffix)     = 'gv';
my($utils)         = GraphViz2::Marpa::Utils -> new;

my($diff, $diff_count);
my($message);

for my $file_name ($utils -> get_files($data_dir_name, $in_suffix) )
{
	$count++;

	$diff       = $utils -> perform_1_test($file_name);
	$diff_count = 0;
	$message    = $will_fail{$file_name}
					? "Known and expected failure : data/$file_name.gv"
					: "Tests shipped and generated: data/$file_name.gv";

	$diff -> Base(1); # Return line numbers, not indices.

	while ($diff -> Next() )
	{
		next if ($diff -> Same);

		$diff_count++;

		my($sep) = '';

		if(! $diff -> Items(2) )
		{
			diag sprintf "%d,%dd%d\n", $diff -> Get(qw(Min1 Max1 Max2) );
		}
		elsif (! $diff -> Items(1) )
		{
			diag sprintf "%da%d,%d\n", $diff -> Get(qw(Max1 Min2 Max2) );
		}
		else
		{
			$sep = "---\n";

			diag sprintf "%d,%dc%d,%d\n", $diff -> Get(qw(Min1 Max1 Min2 Max2) );
		}

		diag sprintf "< $_" for $diff -> Items(1);
		diag sprintf "$sep";
		diag sprintf "> $_" for $diff -> Items(2);
    }

	ok($diff_count == 0, $message);
}

print "# Internal test count: $count\n";

done_testing($count);
