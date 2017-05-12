#!perl -T

use strict;
use warnings;
use Math::Trig;
use Test::More tests => 24;

BEGIN {
    use_ok('Graph::Matching', 'max_weight_matching');
}

diag( "Testing Graph::Matching $Graph::Matching::VERSION, Perl $], $^X" );

# Enable debugging.
$Graph::Matching::CHECK_DELTA = 1;
$Graph::Matching::CHECK_OPTIMUM = 1;

my %m;

# Trivial cases:

%m = max_weight_matching([ ]);
is_deeply(\%m, { }, "empty graph");

%m = max_weight_matching([ [0, 1, 1] ]);
is_deeply(\%m, { 0 => 1, 1 => 0 }, "single edge");

%m = max_weight_matching([ ['one', 'two', 10], ['two', 'three', 11] ]);
is_deeply(\%m, { 'three' => 'two', 'two' => 'three' }, "strings as nodes");

my $q1 = { 1 => 'one' };
my $q2 = { 2 => 'two' };
my $graph = [ [$q1, $q2, 5], [$q2, 3, 11], [3, 4, 5] ];
%m = max_weight_matching($graph);
is_deeply(\%m, { $q2 => 3, 3 => $q2 }, "refs as nodes");
%m = max_weight_matching($graph, 1);
is_deeply(\%m, { $q2 => $q1, 3 => 4, 4 => 3, $q1 => $q2 }, "max cardinality");

# Floating point weights:

{
    local $Graph::Matching::CHECK_DELTA = 0;
    local $Graph::Matching::CHECK_OPTIMUM = 0;
    %m = max_weight_matching(
        [ [1, 2, pi], [2, 3, exp(1)], [1, 3, 3.0], [1, 4, sqrt(2.0)] ]);
    is_deeply(\%m, { 1 => 4, 2 => 3, 3 => 2, 4 => 1 }, "float weights");
}

# Negative weights:

$graph = [ [1, 2, 2], [1, 3, -2], [2, 3, 1], [2, 4, -1], [3, 4, -6] ];
%m = max_weight_matching($graph, 0);
is_deeply(\%m, { 1 => 2, 2 => 1 }, "negative weights");
%m = max_weight_matching($graph, 1);
is_deeply(\%m, { 1 => 3, 2 => 4, 3 => 1, 4 => 2 }, "max cardinality with negative optimum");

# Create S-blossom and use it for augmentation:

%m = max_weight_matching([ [1, 2, 8], [1, 3, 9], [2, 3, 10], [3, 4, 7] ]);
is_deeply(\%m, { 1 => 2, 2 => 1, 3 => 4, 4 => 3 }, "augment through S-blossom");

%m = max_weight_matching([ [1, 2, 8], [1, 3, 9], [2, 3, 10], [3, 4, 7], [1, 6, 5], [4, 5, 6] ]);
is_deeply(\%m, { 1 => 6, 2 => 3, 3 => 2, 4 => 5, 5 => 4, 6 => 1 }, "augment through S-blossom (2)");

# Create S-blossom, relabel as T-blossom, use for augmentation:

%m = max_weight_matching([ [1, 2, 9], [1, 3, 8], [2, 3, 10], [1, 4, 5], [4, 5, 4], [1, 6, 3] ]);
is_deeply(\%m, { 1 => 6, 2 => 3, 3 => 2, 4 => 5, 5 => 4, 6 => 1 }, "augment through T-blossom");

%m = max_weight_matching([ [1, 2, 9], [1, 3, 8], [2, 3, 10], [1, 4, 5], [4, 5, 3], [1, 6, 4] ]);
is_deeply(\%m, { 1 => 6, 2 => 3, 3 => 2, 4 => 5, 5 => 4, 6 => 1 }, "augment through T-blossom (2)");

%m = max_weight_matching([ [1, 2, 9], [1, 3, 8], [2, 3, 10], [1, 4, 5], [4, 5, 3], [3, 6, 4] ]);
is_deeply(\%m, { 1 => 2, 2 => 1, 3 => 6, 4 => 5, 5 => 4, 6 => 3 }, "augment through T-blossom (3)");

# Create nested S-blossom, use for augmentation:

%m = max_weight_matching([ [1, 2, 9], [1, 3, 9], [2, 3, 10], [2, 4, 8], [3, 5, 8], [4, 5, 10], [5, 6, 6] ]);
is_deeply(\%m, { 1 => 3, 2 => 4, 3 => 1, 4 => 2, 5 => 6, 6 => 5 }, "augment through nested S-blossom");

# Create S-blossom, relabel as S, include in nested S-blossom:

%m = max_weight_matching([ [1, 2, 10], [1, 7, 10], [2, 3, 12], [3, 4, 20], [3, 5, 20], [4, 5, 25], [5, 6, 10], [6, 7, 10], [7, 8, 8] ]);
is_deeply(\%m, { 1 => 2, 2 => 1, 3 => 4, 4 => 3, 5 => 6, 6 => 5, 7 => 8, 8 => 7 }, "embed relabeled S-blossom");

# Create nested S-blossom, augment, expand recursively:

%m = max_weight_matching([ [1, 2, 8], [1, 3, 8], [2, 3, 10], [2, 4, 12], [3, 5, 12], [4, 5, 14], [4, 6, 12], [5, 7, 12], [6, 7, 14], [7, 8, 12] ]);
is_deeply(\%m, { 1 => 2, 2 => 1, 3 => 5, 4 => 6, 5 => 3, 6 => 4, 7 => 8, 8 => 7 }, "recursively expand nested S-blossom");

# Create S-blossom, relabel as T, expand:

%m = max_weight_matching([ [1, 2, 23], [1, 5, 22], [1, 6, 15], [2, 3, 25], [3, 4, 22], [4, 5, 25], [4, 8, 14], [5, 7, 13] ]);
is_deeply(\%m, { 1 => 6, 2 => 3, 3 => 2, 4 => 8, 5 => 7, 6 => 1, 7 => 5, 8 => 4 }, "expand T-blossom");

# Create nested S-blossom, relabel as T, expand:

%m = max_weight_matching([ [1, 2, 19], [1, 3, 20], [1, 8, 8], [2, 3, 25], [2, 4, 18], [3, 5, 18], [4, 5, 13], [4, 7, 7], [5, 6, 7], ]);
is_deeply(\%m, { 1 => 8, 2 => 3, 3 => 2, 4 => 7, 5 => 6, 6 => 5, 7 => 4, 8 => 1 }, "expand nested T-blossom");

# Create blossom, relabel as T in more than one way, expand, augment:

%m = max_weight_matching([ [1, 2, 45], [1, 5, 45], [2, 3, 50], [3, 4, 45], [4, 5, 50], [1, 6, 30], [3, 9, 35], [4, 8, 35], [5, 7, 26], [9, 10, 5] ]);
is_deeply(\%m, { 1 => 6, 2 => 3, 3 => 2, 4 => 8, 5 => 7, 6 => 1, 7 => 5, 8 => 4, 9 => 10, 10 => 9 }, "relabel subs of expanded T-blossom");

# Again but slightly different:

%m = max_weight_matching([ [1, 2, 45], [1, 5, 45], [2, 3, 50], [3, 4, 45], [4, 5, 50], [1, 6, 30], [3, 9, 35], [4, 8, 26], [5, 7, 40], [9, 10, 5] ]);
is_deeply(\%m, { 1 => 6, 2 => 3, 3 => 2, 4 => 8, 5 => 7, 6 => 1, 7 => 5, 8 => 4, 9 => 10, 10 => 9 }, "relabel subs of expanded T-blossom (2)");

# Create blossom, relabel as T, expand such that a new least-slack S-to-free edge is produced, augment:

%m = max_weight_matching([ [1, 2, 45], [1, 5, 45], [2, 3, 50], [3, 4, 45], [4, 5, 50], [1, 6, 30], [3, 9, 35], [4, 8, 28], [5, 7, 26], [9, 10, 5] ]);
is_deeply(\%m, { 1 => 6, 2 => 3, 3 => 2, 4 => 8, 5 => 7, 6 => 1, 7 => 5, 8 => 4, 9 => 10, 10 => 9 }, "mark least-slack after expanding T-blossom");

# Create nested blossom, relabel as T in more than one way, expand outer blossom such that inner blossom ends up on an augmenting path:

%m = max_weight_matching([ [1, 2, 45], [1, 7, 45], [2, 3, 50], [3, 4, 45], [4, 5, 95], [4, 6, 94], [5, 6, 94], [6, 7, 50], [1, 8, 30], [3, 11, 35], [5, 9, 36], [7, 10, 26], [11, 12, 5] ]);
is_deeply(\%m, { 1 => 8, 2 => 3, 3 => 2, 4 => 6, 5 => 9, 6 => 4, 7 => 10, 8 => 1, 9 => 5, 10 => 7, 11 => 12, 12 => 11 }, "augment through inner blossom after expanding outer T-blossom");

# Create nested S-blossom, relabel as S, expand recursively:

%m = max_weight_matching([ [1, 2, 40], [1, 3, 40], [2, 3, 60], [2, 4, 55], [3, 5, 55], [4, 5, 50], [1, 8, 15], [5, 7, 30], [7, 6, 10], [8, 10, 10], [4, 9, 30] ]);
is_deeply(\%m, { 1 => 2, 2 => 1, 3 => 5, 4 => 9, 5 => 3, 6 => 7, 7 => 6, 8 => 10, 9 => 4, 10 => 8 }, "recursively expand nested S-blossom (2)");

# end.
