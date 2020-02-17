#!perl

use strict;
use warnings;
use Math::Trig ':pi';

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Game::RaycastFOV;

can_ok('Game::RaycastFOV',
    qw(bypair cached_circle circle line raycast swing_circle));

# XS - bypair
{
    dies_ok { Game::RaycastFOV::bypair {} 1 } 'wrong number of arguments';
    # how can this condition be triggered?
    #dies_ok { Game::RaycastFOV::bypair { @_ } 1, 2 } 'multiple return values';

    my @pairs;
    Game::RaycastFOV::bypair { push @pairs, $_[1], $_[0] } qw(1 2 3 4);
    $deeply->(\@pairs, [qw(2 1 4 3)]);

    @pairs = ();
    Game::RaycastFOV::bypair { push @pairs, $_[1]; -1 } qw(1 2 3 4);
    $deeply->(\@pairs, [qw(2)]);
}

# XS - circle
{
    my @pairs;
    Game::RaycastFOV::circle { push @pairs, @_ } 0, 0, 1;
    # KLUGE this is going to depend on the order of operations in the
    # code, might ideally form up points and sort them, and also test
    # larger circles
    $deeply->(
        \@pairs, [qw/0 1 0 -1 1 0 -1 0 1 0 -1 0 1 0 -1 0 0 1 0 1 0 -1 0 -1/]
    );

    @pairs = ();
    Game::RaycastFOV::circle { push @pairs, @_ } 1, -1, 1;
    $deeply->(
        \@pairs, [qw/1 0 1 -2 2 -1 0 -1 2 -1 0 -1 2 -1 0 -1 1 0 1 0 1 -2 1 -2/]
    );
}

# XS - line
{
    my @pairs;
    Game::RaycastFOV::line { push @pairs, @_ } 0, 0, 2, 2;
    $deeply->(\@pairs, [qw/0 0 1 1 2 2/]);

    @pairs = ();
    Game::RaycastFOV::line { push @pairs, @_ } 0, 0, 0, 0;
    $deeply->(\@pairs, [qw/0 0/]);

    @pairs = ();
    Game::RaycastFOV::line { push @pairs, @_; return -1 if $_[0] > 1 }
    0, 0, 5, 0;
    $deeply->(\@pairs, [qw/0 0 1 0 2 0/]);
}

# cached_circle
{
    my @pairs;
    Game::RaycastFOV::cached_circle { push @pairs, @_ } 0, 0, 1;
    $deeply->(\@pairs, [qw/1 0 1 1 0 1 -1 1 -1 0 -1 -1 0 -1 1 -1/]);

    @pairs = ();
    Game::RaycastFOV::cached_circle { push @pairs, @_ } 5, 4, 1;
    $deeply->(\@pairs, [qw/6 4 6 5 5 5 4 5 4 4 4 3 5 3 6 3/]);
}

# swing_circle
{
    my @pairs;
    Game::RaycastFOV::swing_circle { push @pairs, @_ } 0, 0, 1, pip4;
    $deeply->(\@pairs, [qw/1 0 1 1 0 1 -1 1 -1 0 -1 -1 0 -1 1 -1/]);

    @pairs = ();
    Game::RaycastFOV::swing_circle { push @pairs, @_ } -1, 1, 1, pip4;
    $deeply->(\@pairs, [qw/0 1 0 2 -1 2 -2 2 -2 1 -2 0 -1 0 0 0/]);
}

# raycast
{
    my (@pairs, %seen);
    Game::RaycastFOV::raycast(\&Game::RaycastFOV::circle,
        sub { push @pairs, @_ unless $seen{"@_"}++ },
        0, 0, 2);
    $deeply->(
        \@pairs,
        [   qw/0 0 0 1 0 2 0 -1 0 -2 1 0 2 0 -1 0 -2 0 1 2 -1 2 1 -2 -1 -2 2 1 -2 1 2 -1 -2 -1/
        ]
    );

    %seen = @pairs = ();
    Game::RaycastFOV::raycast(\&Game::RaycastFOV::circle,
        sub { push @pairs, @_ unless $seen{"@_"}++ },
        -2, 2, 1);
    $deeply->(\@pairs, [qw/-2 2 -2 3 -2 1 -1 2 -3 2/]);
}

done_testing 15
