#!perl

use strict;
use warnings;
use Math::Trig ':pi';

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Game::RaycastFOV;

can_ok 'Game::RaycastFOV',
  qw(bypair bypairall cached_circle circle line raycast shadowcast swing_circle);

# XS - bypair
{
    dies_ok { Game::RaycastFOV::bypair {} 1 } 'wrong number of arguments';

    lives_ok { Game::RaycastFOV::bypair {} };
    # "Use of uninitialized value in subroutine entry" -- would probably
    # need to check if sub has nothing in it? probably rare, so only
    # document here
    #lives_ok { Game::RaycastFOV::bypair {} qw(a b c d) };
    lives_ok {
        Game::RaycastFOV::bypair { return 42, 43 }
    };
    lives_ok {
        Game::RaycastFOV::bypair { return 42, 43 } qw(a b c d)
    };

    my @pairs;
    Game::RaycastFOV::bypair { push @pairs, $_[1], $_[0] } qw(a b c d);
    $deeply->( \@pairs, [qw(b a d c)] );

    # abort early
    my $count = 0;
    Game::RaycastFOV::bypair { $count++; return -1 } qw(1 2 3 4);
    is $count, 1;
}

# XS - bypairall
{
    dies_ok { Game::RaycastFOV::bypairall {} 1 } 'wrong number of arguments';

    my $count = 0;
    # MUST NOT abort on -1 (or any) return, unlike previous does
    Game::RaycastFOV::bypairall { $count++; return -1 } qw(1 2 3 4 7 6);
    is $count, 3;
}

# XS - circle
{
    my @pairs;
    Game::RaycastFOV::circle { push @pairs, @_ } 0, 0, 1;
    # KLUGE this is going to depend on the order of operations in the
    # code, might ideally form up points and sort them, and also test
    # larger circles. but at least the list is unique, now...
    $deeply->( \@pairs, [qw/0 1 0 -1 1 0 -1 0/] );

    @pairs = ();
    Game::RaycastFOV::circle { push @pairs, @_ } 1, -1, 1;
    $deeply->( \@pairs, [qw/1 0 1 -2 2 -1 0 -1/] );
}

# XS - line
{
    my @pairs;
    Game::RaycastFOV::line { push @pairs, @_ } 0, 0, 2, 2;
    $deeply->( \@pairs, [qw/0 0 1 1 2 2/] );

    # NOTE the Game::Xomb line code instead skips the first point on the
    # line as it is not concerned where the player/monster is
    @pairs = ();
    Game::RaycastFOV::line { push @pairs, @_ } 0, 0, 0, 0;
    $deeply->( \@pairs, [qw/0 0/] );

    # abort early
    @pairs = ();
    Game::RaycastFOV::line { return -1 if $_[0] < 4; push @pairs, @_ }
    5, 5, 0, 0;
    $deeply->( \@pairs, [qw/5 5 4 4/] );
}

# cached_circle
{
    my @pairs;
    Game::RaycastFOV::cached_circle { push @pairs, @_ } 0, 0, 1;
    $deeply->( \@pairs, [qw/1 0 1 1 0 1 -1 1 -1 0 -1 -1 0 -1 1 -1/] );

    @pairs = ();
    Game::RaycastFOV::cached_circle { push @pairs, @_ } 5, 4, 1;
    $deeply->( \@pairs, [qw/6 4 6 5 5 5 4 5 4 4 4 3 5 3 6 3/] );
}

# swing_circle - calls XS sub_circle
{
    my @pairs;
    Game::RaycastFOV::swing_circle { push @pairs, @_ } 0, 0, 1, pip4;
    $deeply->( \@pairs, [qw/1 0 1 1 0 1 -1 1 -1 0 -1 -1 0 -1 1 -1/] );

    @pairs = ();
    Game::RaycastFOV::swing_circle { push @pairs, @_ } -1, 1, 1, pip4;
    $deeply->( \@pairs, [qw/0 1 0 2 -1 2 -2 2 -2 1 -2 0 -1 0 0 0/] );

    my $count = 0;
    Game::RaycastFOV::swing_circle { $count++ } 0, 0, 1, 0.01;
    is $count, 8;
}

# raycast
{
    my ( @pairs, %seen );
    Game::RaycastFOV::raycast( \&Game::RaycastFOV::circle,
        sub { push @pairs, @_ unless $seen{"@_"}++ },
        0, 0, 2 );
    $deeply->(
        \@pairs,
        [   qw/0 0 0 1 0 2 0 -1 0 -2 1 0 2 0 -1 0 -2 0 1 2 -1 2 1 -2 -1 -2 2 1 -2 1 2 -1 -2 -1/
        ]
    );

    %seen = @pairs = ();
    Game::RaycastFOV::raycast( \&Game::RaycastFOV::circle,
        sub { push @pairs, @_ unless $seen{"@_"}++ },
        -2, 2, 1 );
    $deeply->( \@pairs, [qw/-2 2 -2 3 -2 1 -1 2 -3 2/] );

    # is the raycast leaking through walls? (Game::Xomb had a bug along
    # these lines due to the complicated environment checks, and so did
    # an early version of the shadowcast implementation...)
    #
    # non-symmetrical so that x,y is less likely confused with y,x
    my @map = (
        [qw/0 0 0 0 0 0/],
        [qw/0 1 1 1 1 0/],
        [qw/0 1 0 0 1 0/],    # 2,2 center for player
        [qw/0 1 1 1 1 0/],
        [qw/0 0 0 0 0 0/],
    );
    my @visible;
    %seen = ();
    Game::RaycastFOV::raycast(
        \&Game::RaycastFOV::cached_circle,
        sub {
            my ( $lx, $ly ) = @_;
            if ( $lx < 0 or $lx >= 5 or $ly < 0 or $ly >= 5 ) {
                BAIL_OUT("out of bounds cell check?? $lx,$ly");
                return -1;
            }
            push @visible, [ $lx, $ly ] unless $seen{ $lx . ',' . $ly }++;
            return -1 if $map[$ly][$lx] == 1;    # blocked
        },
        2,
        2,
        3
    );
    $deeply->(
        [ sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @visible ],
        [   [ 1, 1 ], [ 1, 2 ], [ 1, 3 ], [ 2, 1 ], [ 2, 2 ], [ 2, 3 ],
            [ 3, 1 ], [ 3, 2 ], [ 3, 3 ], [ 4, 1 ], [ 4, 2 ], [ 4, 3 ],
        ]
    );
}

done_testing 22
