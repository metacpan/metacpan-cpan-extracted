#!perl

use strict;
use warnings;
use Game::RaycastFOV qw(shadowcast);
use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

# non-symmetrical so that x,y is less likely confused with y,x
my @map = (
    [qw/0 0 0 0 0 0/],
    [qw/0 1 1 1 1 0/],
    [qw/0 1 0 0 1 0/],    # 2,2 center for player
    [qw/0 1 1 1 1 0/],
    [qw/0 0 0 0 0 0/]
);

my (%seen, @visible);

# first aid cross of radius 1
#
# hmm this is revisiting some points more than once (wasn't shadowcast
# supposed to avoid that unlike raycast? or is it better about
# trimming dups?)
shadowcast(
    2, 2, 1,
    sub { return 0 },    # not blocked
    sub {                # visible cell
        my ($curx, $cury, $dx, $dy) = @_;
        push @visible, [ $curx, $cury ] unless $seen{ $curx . ',' . $cury }++;
    },
    sub {                # within radius?
        my ($dx, $dy) = map { abs } @_;
        return ($dx + $dy) <= 1;
    }
);

$deeply->(
    [ sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @visible ],
    [ [ 1, 2 ], [ 2, 1 ], [ 2, 2 ], [ 2, 3 ], [ 3, 2 ] ]
);

# equivalent to the "is the raycast leaking through walls?" of raycast.t
%seen = @visible = ();
shadowcast(
    2, 2, 5,
    sub {
        my ($curx, $cury) = @_;
        return $map[$cury][$curx] == 1;
    },
    sub {
        my ($curx, $cury, $dx, $dy) = @_;
        push @visible, [ $curx, $cury ] unless $seen{ $curx . ',' . $cury }++;
    },
    sub { return 1 }
);

$deeply->(
    [ sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @visible ],
    [   [ 1, 1 ], [ 1, 2 ], [ 1, 3 ], [ 2, 1 ], [ 2, 2 ], [ 2, 3 ],
        [ 3, 1 ], [ 3, 2 ], [ 3, 3 ], [ 4, 1 ], [ 4, 2 ], [ 4, 3 ],
    ]
);

done_testing 2
