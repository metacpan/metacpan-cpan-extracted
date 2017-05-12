package Game::Battleship;
our $AUTHORITY = 'cpan:GENE';
# ABSTRACT: "You sunk my battleship!"

our $VERSION = '0.0601';

use Carp;
use Game::Battleship::Player;
use Moo;


has players => (
    is  => 'rw',
    isa => sub { croak 'Invalid players list' unless ref($_[0]) eq 'HASH' },
);


sub add_player {
    my ($self, $player, $i) = @_;

    # If we are not given a number to use...
    unless ($i) {
        # ..find the least whole number that is not already used.
        my @nums = sort { $a <=> $b }
            grep { s/^player_(\d+)$/$1/ }
                keys %{ $self->{players} };
        my $n = 1;
        for (@nums) {
            last if $n > $_;
            $n++;
        }
        $i = $n;
    }

    # Make the name to use for our object.
    my $who = "player_$i";

    # Return undef if we are trying to add an existing player.
    if ( exists $self->{players}{$who} ) {
        warn "A player number $i already exists\n";
        return;
    }

    # Set the player name unless we already have a player.
    $player = $who unless $player;

    # We are given a player object.
    if (ref ($player) eq 'Game::Battleship::Player') {
        $self->{players}{$who} = $player;
    }
    # We are given the guts of a player.
    elsif (ref ($player) eq 'HASH') {
        $self->{players}{$who} = Game::Battleship::Player->new(
            id => $player->{id} || $i,
            name => $player->{name} || $who,
            fleet => $player->{fleet},
            dimensions => $player->{dimensions},
        );
    }
    # We are just given a name.
    else {
        $self->{players}{$who} = Game::Battleship::Player->new(
            id   => $i,
            name => $player,
        );
    }

    # Hand the player object back.
    return $self->{players}{$who};
}


sub player {
    my ($self, $name) = @_;
    my $player;

    # Step through each player...
    for (keys %{ $self->{players} }) {
        # Are we looking at the same player by name, key or id?
        if( $_ eq $name ||
            $self->{players}{$_}->name eq $name ||
            $self->{players}{$_}->id eq $name
        ) {
            # Set the player object to return.
            $player = $self->{players}{$_};
            last;
        }
    }

    warn "No such player '$name'\n" unless $player;
    return $player;
}


sub play {
    my ($self, %args) = @_;
    my $winner = 0;

    while (not $winner) {
        # Take a turn per live player.
        for my $player (values %{ $self->{players} }) {
            next unless $player->life;

            # Strike each opponent.
            for my $opponent (values %{ $self->{players} }) {
                next if $opponent->name eq $player->name ||
                    !$opponent->life;

                my $res = -1;  # "duplicate strike" flag.
                while ($res == -1) {
                    $res = $player->strike(
                        $opponent,
                        $self->_get_coordinate($opponent)
                    );
                }
            }
        }

        # Do we have a winner?
        my @alive = grep { $self->{players}{$_}->life } keys %{ $self->{players} };
        $winner = @alive == 1 ? shift @alive : undef;
    }

#warn $winner->name ." is the winner!\n";
    return $winner;
}

# Return a coordinate from a player's grid.
sub _get_coordinate {
    my ($self, $player) = @_;

    my ($x, $y);

    # Return random coordinates...
    ($x, $y) = (
        int 1 + rand $player->{grid}->{dimension}[0],
        int 1 + rand $player->{grid}->{dimension}[1]
    );

#    warn "$x, $y\n";
    return $x, $y;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Game::Battleship - "You sunk my battleship!"

=head1 VERSION

version 0.0601

=head1 SYNOPSIS

  use Game::Battleship;
  my $g = Game::Battleship->new;
  $g->add_player('Aaron');
  $g->add_player('Tabi');
  my $winner = $g->play();
  print $winner->name(), " wins!\n";

=head1 DESCRIPTION

A C<Game::Battleship> object represents a battleship game between
players.  Each has a fleet of vessels and operates with a pair of
playing grids.  One grid is for their own fleet and the other for
the seen enemy positions.

Everything is an object with default but mutable attributes.  This way
games can have two or more players each with a single fleet of custom
vessels.

A game can be played with the handy C<play()> method or for finer
control, use individual methods of the C<Game::Battleship::*>
modules.  See the distribution test script for working code examples.

=head1 NAME

Game::Battleship - "You sunk my battleship!"

=head1 METHODS

=head2 B<new()>

  $g = Game::Battleship->new;
  $g = Game::Battleship->new( players => [$player1, $player2] );

Construct a new C<Game::Battleship> object.

=head2 B<add_player()>

  $g->add_player;
  $g->add_player($name);
  $g->add_player({
      name => $name,
      fleet => \@fleet,
      dimensions => [$w, $h],
  });
  $g->add_player($player, $number);

Add a player to the existing game.

This method can accept either nothing, a string, a
C<Game::Battleship::Player> object or a hash reference
of meaningful C<Game::Battleship::Player> attributes.

This method also accepts an optional numeric second argument that is
the player number.

If this number is not provided, the least whole number that is not
represented in the player IDs is used.  If a player already exists
with that number, a warning is emitted and the player is not added.

See L<Game::Battleship::Player> for details on the default and custom
settings.

=head2 B<player()>

  $player_obj = $g->player($name);
  $player_obj = $g->player($number);
  $player_obj = $g->player($key);

Return the C<Game::Battle::Player> object that matches the given
name, key or number (where the key is C</player_\d+/> and the number
is just the numeric part of the key).

=head2 B<play()>

  $winner = $g->play;

Take a turn for each player, striking all the opponents, until there
is only one player left alive.

Return the C<Game::Battleship::Player> object that is the game
winner.

=head1 TO DO

Implement the "number of shots" measure.  This may be based on life
remaining, shots taken, hits made or ships sunk (etc?).

Enhance weaponry and sensing.

=head1 SEE ALSO

* The code in the C<t/> directory.

* L<Game::Battleship::Craft>, L<Game::Battleship::Grid>, L<Game::Battleship::Player>

* L<http://en.wikipedia.org/wiki/Battleship_%28game%29>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
