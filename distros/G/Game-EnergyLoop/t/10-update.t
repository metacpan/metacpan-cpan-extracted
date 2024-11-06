#!perl
# does update() work?
use strict;
use warnings;

# Mock object to test the interface with
package Game::EnergyLoop::Test;

our @mins;

sub new {
    my ( $class, $energy ) = @_;
    my $self;
    $self->{_energy} = $energy;
    $self->{_id}     = $energy;
    return bless $self, $class;
}

sub enlo_energy {
    my ( $self, $new ) = @_;
    $self->{_energy} = $new if defined $new;
    return $self->{_energy};
}

# NOTE the enlo_update function should not modify the _energy value; if
# that is necessary one probably wants a different interface where
# enlo_update is responsible for setting the energy value (which may be
# easy to forget to do, which is why this interface has it as a return
# value, or that in an older version of this code the energy was stored
# elsewhere, there being no object to stuff it into.)
sub enlo_update {
    my ( $self, $min, $arg ) = @_;
    push @$arg, $self->{_id};
    push @mins, $min;
    if ( $self->{_energy} == 0 ) {
        return 1;
    }
    return -1;    # landmine, shouldn't be reached
}

# And now for the tests
package main;
use Test2::V0;
use Game::EnergyLoop;

my @animates = map { Game::EnergyLoop::Test->new($_) } 1 .. 2;
my @order;

# 1 goes before 2 as 1 hits 0 first; new energy for both is 1 due to
# enlo_update modifying only the one that ran
my $cost = Game::EnergyLoop::update( \@animates, undef, \@order );
is \@Game::EnergyLoop::Test::mins,      [1];
is $cost,                               1;
is [ map { $_->{_energy} } @animates ], [ 1, 1 ];
is [ map { $_->{_id} } @animates ],     [ 1, 2 ];
is \@order,                             [1];

# Now with two entities that update at the same time, both having cost 1
sub initiative {
    my ($ani) = @_;
    @$ani = reverse @$ani;
}

@order = ();
Game::EnergyLoop::update( \@animates, \&initiative, \@order );
is [ map { $_->{_energy} } @animates ], [ 1, 1 ];
is [ map { $_->{_id} } @animates ],     [ 1, 2 ];    # unchanged
is \@order,                             [ 2, 1 ];    # reversed!

# Test coverage holes
{
    no warnings qw(redefine);

    # Mook Maker 3000 - update function spawns more entities
    *Game::EnergyLoop::Test::enlo_update = sub {
        my ( $self, $arg ) = @_;
        return 1, [ map { Game::EnergyLoop::Test->new( $_ * 10 ) } 1 .. 2 ];
    };
    # ... with a reset so only one entity spawns entities and also
    # covering a fiddly logic edge case
    @animates = ( Game::EnergyLoop::Test->new(1) );
    Game::EnergyLoop::update( \@animates, \&initiative );
    is [ map { $_->{_id} } @animates ], [ 1, 10, 20 ];

    # Being negative in various ways...
    *Game::EnergyLoop::Test::enlo_update = sub {
        my ( $self, $arg ) = @_;
        return -42;
    };
    like( dies { Game::EnergyLoop::update( \@animates ) },
        qr{negative entity new_energy -42} );

    @animates = ( Game::EnergyLoop::Test->new(-640) );
    like( dies { Game::EnergyLoop::update( \@animates ) },
        qr{negative minimum energy -640} );
}

# One might instead throw an error if there are not any objects, or this
# "shouldn't happen" during a game as a game-over condition should make
# the code go elsewhere. In theory. (A different interface might return
# -1 if there wasn't anything to loop over, or could throw an error.)
$cost = Game::EnergyLoop::update( [] );
is $cost, ~0;

done_testing 17
