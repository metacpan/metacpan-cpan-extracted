#!/usr/bin/env perl

# Tests for the per-link line restriction feature.
#
#   <station id="B" ... link="A:x,C"/>
#
# means the link from B to A only runs on line 'x', even if B and A are
# both nominally on lines x and y. A link with no colon (e.g. plain "C")
# is unrestricted and behaves exactly as before.
#
# Multiple restricted lines for a single link are pipe-separated, e.g.
# link="A:x|y,C".

package RestrictedMap;

use Moo;
use namespace::autoclean;

has xml => (is => 'ro', default => sub { File::Spec->catfile('t', 'map-link-restricted.xml') });
with 'Map::Tube';

package UnrestrictedMap;

use Moo;
use namespace::autoclean;

has xml => (is => 'ro', default => sub { File::Spec->catfile('t', 'map-link-unrestricted.xml') });
with 'Map::Tube';

package InvalidLineMap;

use Moo;
use namespace::autoclean;

has xml => (is => 'ro', default => sub { File::Spec->catfile('t', 'map-link-invalid.xml') });
with 'Map::Tube';

package MultiRestrictedMap;

use Moo;
use namespace::autoclean;

has xml => (is => 'ro', default => sub { File::Spec->catfile('t', 'map-link-multi.xml') });
with 'Map::Tube';

package main;

use v5.14;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use Test::More;

# 1. Backward compatibility: parsing still works when nothing is
#    restricted, and the linked-station list is exactly as expected.
{
    my $map    = UnrestrictedMap->new;
    my $linked = $map->get_linked_stations('B street');
    is_deeply(
        [ sort @$linked ], [ sort ('A street', 'C street') ],
        'unrestricted map: B street correctly linked to A street and C street'
    );
}

# 2. The restricted map parses the "A:x" style link down to a clean
#    station id -- B is still actually linked to A and C.
{
    my $map    = RestrictedMap->new;
    my $linked = $map->get_linked_stations('B street');
    is_deeply(
        [ sort @$linked ], [ sort ('A street', 'C street') ],
        'restricted map: "A:x" link still resolves to A street (plus C street)'
    );
}

# 3. The restriction changes routing. On this map, B -> D has two
#    equal-hop-count routes: B-A-D and B-C-D. Without any restriction,
#    the line-change penalty is identical on both, so the router picks
#    the first one it discovers (B-A-D). With B's link to A restricted
#    to line x, arriving at A can only be "on" line x, which then forces
#    an extra line change onto D (line y only) -- so the router should
#    now prefer the unrestricted B-C-D path instead.
{
    my $map   = UnrestrictedMap->new;
    my $route = $map->get_shortest_route('B street', 'D street');
    is(
        "$route",
        'B street (Line X, Line Y), A street (Line X, Line Y), D street (Line Y)',
        'unrestricted map: B -> D goes via A (no penalty either way, first found wins)'
    );
}

{
    my $map   = RestrictedMap->new;
    my $route = $map->get_shortest_route('B street', 'D street');
    is(
        "$route",
        'B street (Line X, Line Y), C street (Line X, Line Y), D street (Line Y)',
        'restricted map: B -> D now goes via C, avoiding the forced line-change through the restricted B-A link'
    );
}

# 4. A restriction naming a line that doesn't exist on the map should
#    raise a clear exception rather than fail silently or crash oddly.
{
    my $ok    = eval { InvalidLineMap->new; 1 };
    my $error = $@;
    ok(!$ok, 'invalid restricted line id causes construction to fail');
    isa_ok($error, 'Map::Tube::Exception::InvalidStationLineId')
        if ref $error;
    like(
        "$error", qr/Invalid restricted line \[z\]/,
        'exception message names the offending line and is not silently swallowed'
    ) if ref $error;
}

# 5. Multiple restricted lines for a single link (pipe-separated)
#    parse without error and still resolve to the correct station.
{
    my $map    = MultiRestrictedMap->new;
    my $linked = $map->get_linked_stations('B street');
    is_deeply(
        [ sort @$linked ], [ 'A street' ],
        'multi-line restriction ("A:x|y") parses correctly and still links to A street'
    );
}

done_testing;
