#!/usr/bin/env perl

# Tests for two follow-up fixes to the per-link line restriction feature,
# both surfaced by review feedback on a map with directional restrictions:
#
#   <station id="B" name="B" line="x,y" link="A:x,C"/>
#   <station id="C" name="C" line="x,y" link="B:x,D"/>
#
# i.e. B's link to A only runs on line x, and C's link to B only runs on
# line x. Since neither restriction is mirrored on the other side (A's own
# link to B, and B's own link to C, are both left unrestricted), this map
# describes a one-way loop on line Y: A -> B -> C -> D -> A, with no
# reverse edges valid on Y at all.
#
# Fix 1: Map::Tube::Route::preferred() must take per-edge restrictions
#        into account when deciding which line(s) to display at each hop,
#        not just each station's full line membership.
#
# Fix 2: get_next_stations() / get_linked_stations() gained an optional
#        $line_name filter, so callers (e.g. CLI tools, graph generators)
#        can ask "who is linked to this station specifically on line X",
#        and get an answer that honors restrictions -- instead of the
#        previous behavior, which always returned every physically-linked
#        neighbor regardless of which line was asked about.

package LoopMap;

use Moo;
use namespace::autoclean;

has xml => (is => 'ro', default => sub { File::Spec->catfile('t', 'map-link-loop.xml') });
with 'Map::Tube';

package main;

use v5.14;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use Test::More;

my $map = LoopMap->new;

# --- Fix 1: preferred() respects the restriction ---------------------------
# On this map every hop except A->B->C->D->A is symmetric, so the plain
# get_shortest_route()/as_string ("A (Line X, Line Y)" style) can't tell
# these apart -- preferred() is specifically what narrows the display down
# to the line(s) actually usable on each edge.

is(
    $map->get_shortest_route('B', 'A')->preferred(),
    'B (Line X), A (Line X)',
    'preferred(): B -> A only shows Line X (B\'s link to A is X-restricted)'
);

is(
    $map->get_shortest_route('C', 'B')->preferred(),
    'C (Line X), B (Line X)',
    'preferred(): C -> B only shows Line X (C\'s link to B is X-restricted)'
);

is(
    $map->get_shortest_route('A', 'B')->preferred(),
    'A (Line X, Line Y), B (Line X, Line Y)',
    'preferred(): A -> B is unrestricted, so both lines still show'
);

# --- Fix 2: get_linked_stations()/get_next_stations() line filter ----------

# Without a line filter, behavior is unchanged: every physical neighbor.
is_deeply(
    [ sort @{ $map->get_linked_stations('B') } ],
    [ sort ('A', 'C') ],
    'get_linked_stations(B): no line filter returns all physical neighbors'
);

# On Line Y, this map is a strict one-way loop: A->B->C->D->A, no reverse
# edges at all. This is exactly the case the CLI/graph tooling got wrong
# before this fix (it always showed both directions).
is_deeply( $map->get_linked_stations('A', 'Line Y'), ['B'], 'Line Y: A -> B only' );
is_deeply( $map->get_linked_stations('B', 'Line Y'), ['C'], 'Line Y: B -> C only (not back to A)' );
is_deeply( $map->get_linked_stations('C', 'Line Y'), ['D'], 'Line Y: C -> D only (not back to B)' );
is_deeply( $map->get_linked_stations('D', 'Line Y'), ['A'], 'Line Y: D -> A only' );

# On Line X, B and C's restricted links still count (the restriction lists
# X as an allowed line), so X is fully bidirectional between A-B and B-C.
# D has no presence on line X at all, so it must show zero neighbors on X,
# not merely "whatever D happens to link to physically".
is_deeply( [ sort @{ $map->get_linked_stations('A', 'Line X') } ], ['B'],      'Line X: A -> B' );
is_deeply( [ sort @{ $map->get_linked_stations('B', 'Line X') } ], ['A','C'], 'Line X: B -> A, C' );
is_deeply( [ sort @{ $map->get_linked_stations('C', 'Line X') } ], ['B'],      'Line X: C -> B' );
is_deeply( [ sort @{ $map->get_linked_stations('D', 'Line X') } ], [],        'Line X: D has no line-X neighbors (D is not on line X at all)' );

# An unknown line name should throw rather than silently return nothing.
{
    my $ok = eval { $map->get_linked_stations('A', 'NoSuchLine'); 1 };
    ok(!$ok, 'get_linked_stations() with an unknown line name throws');
    like(
        "$@", qr/Invalid Line Name \[NoSuchLine\]/,
        'exception clearly names the unknown line'
    );
}

done_testing;
