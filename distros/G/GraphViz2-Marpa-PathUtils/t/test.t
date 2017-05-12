#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny 'capture';

use File::Spec;

use GraphViz2::Marpa::PathUtils;

use Test::More;

# -------------

sub check_clusters
{
	my($input_file) = @_;

	my($stdout, $stderr) = capture
	{
		GraphViz2::Marpa::PathUtils -> new
		(
			input_file      => File::Spec -> catfile('data', $input_file),
			report_clusters => 1,
		) -> find_clusters
	};

	return $stdout;
}

# -------------

sub check_fixed
{
	my($input_file, $start_node) = @_;

	my($stdout, $stderr) = capture
	{
		GraphViz2::Marpa::PathUtils -> new
		(
			input_file   => File::Spec -> catfile('data', $input_file),
			report_paths => 1,
			start_node   => $start_node,
			path_length  => 3,
		) -> find_fixed_length_paths
	};

	return $stdout;
}

# -------------

my($count) = 6;

my($expected);
my($stdout);

# Test 1.

$stdout   = check_clusters('clusters.in.06.gv');
$expected = <<'EOS';
Input file: clusters.in.06.gv. Clusters: 4:
Cluster: 1. (A B C D E)
Cluster: 2. (J K)
Cluster: 3. (F G)
Cluster: 4. (H I)
EOS

ok($stdout eq $expected);

# Test 2.

$stdout   = check_clusters('clusters.in.07.gv');
$expected = <<'EOS';
Input file: clusters.in.07.gv. Clusters: 4:
Cluster: 1. (B C)
Cluster: 2. (H I J K L M N O)
Cluster: 3. (D E F G)
Cluster: 4. (A)
EOS

ok($stdout eq $expected);

# Test 3.

$stdout   = check_clusters('clusters.in.09.gv');
$expected = <<'EOS';
Input file: clusters.in.09.gv. Clusters: 7:
Cluster: 1. (a b)
Cluster: 2. (i j k l)
Cluster: 3. (c d e)
Cluster: 4. (f g h)
Cluster: 5. (x)
Cluster: 6. (y)
Cluster: 7. (z)
EOS

ok($stdout eq $expected);

# Test 4.

$stdout   = check_fixed('fixed.length.paths.in.01.gv', 'Act_1');
$expected = <<'EOS';
Input file: fixed.length.paths.in.01.gv. Starting node: Act_1. Path length: 3. Allow cycles: 0. Paths: 4:
Path: 1. Act_1 -> Act_23 -> Act_25 -> Act_3
Path: 2. Act_1 -> Act_23 -> Act_24 -> Act_25
Path: 3. Act_1 -> Act_21 -> Act_22 -> Act_24
Path: 4. Act_1 -> Act_21 -> Act_22 -> Act_23
EOS

ok($stdout eq $expected);

# Test 5.

$stdout   = check_fixed('fixed.length.paths.in.02.gv', '5');
$expected = <<'EOS';
Input file: fixed.length.paths.in.02.gv. Starting node: 5. Path length: 3. Allow cycles: 0. Paths: 12:
Path: 1. 5 -> 8 -> 6 -> 9
Path: 2. 5 -> 8 -> 6 -> 1
Path: 3. 5 -> 8 -> 3 -> 2
Path: 4. 5 -> 8 -> 3 -> 4
Path: 5. 5 -> 7 -> 9 -> 6
Path: 6. 5 -> 7 -> 9 -> 4
Path: 7. 5 -> 7 -> 2 -> 1
Path: 8. 5 -> 7 -> 2 -> 3
Path: 9. 5 -> 0 -> 4 -> 9
Path: 10. 5 -> 0 -> 4 -> 3
Path: 11. 5 -> 0 -> 1 -> 6
Path: 12. 5 -> 0 -> 1 -> 2
EOS

ok($stdout eq $expected);

# Test 6.

$stdout   = check_fixed('fixed.length.paths.in.03.gv', 'A');
$expected = <<'EOS';
Input file: fixed.length.paths.in.03.gv. Starting node: A. Path length: 3. Allow cycles: 0. Paths: 8:
Path: 1. A -> B -> C -> D
Path: 2. A -> B -> C -> D
Path: 3. A -> B -> C -> D
Path: 4. A -> B -> C -> D
Path: 5. A -> B -> C -> D
Path: 6. A -> B -> C -> D
Path: 7. A -> B -> C -> D
Path: 8. A -> B -> C -> D
EOS

ok($stdout eq $expected);

print "# Internal test count: $count. \n";

done_testing($count);
