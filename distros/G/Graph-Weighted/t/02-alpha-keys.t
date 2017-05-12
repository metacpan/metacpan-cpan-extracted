#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Graph::Weighted';

my $g = Graph::Weighted->new;

$g->populate(
    {
        A => { A => 1, B => 1 },
        B => { A => 1, B => 1 },
        C => { A => 1, B => 1 },
        D => { A => 1, B => 1 },
    }
);

for my $i ( $g->vertices ) {
    is_deeply [ sort $g->successors($i) ], [qw( A B )], "successors of $i";
}

done_testing();
