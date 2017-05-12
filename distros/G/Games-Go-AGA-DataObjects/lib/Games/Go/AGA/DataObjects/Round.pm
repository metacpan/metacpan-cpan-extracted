#===============================================================================
#
#         FILE:  Games::Go::AGA::DataObjects::Round.pm
#
#        USAGE:  use Games::Go::AGA::DataObjects::Round;
#
#      PODNAME:  Games::Go::AGA::DataObjects::Round
#     ABSTRACT:  model a round of an AGA tournament
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#      CREATED:  11/19/2010 03:13:05 PM PST
#===============================================================================

use strict;
use warnings;

package Games::Go::AGA::DataObjects::Round;
use Moo;
use namespace::clean;

use Carp;
use Scalar::Util qw( refaddr looks_like_number );
use Games::Go::AGA::DataObjects::Game;
use Games::Go::AGA::DataObjects::Player;
use Games::Go::AGA::DataObjects::Types qw( is_Int isa_Int isa_CodeRef);
use Games::Go::AGA::Parse::Util qw( normalize_ID Rank_to_Rating );

our $VERSION = '0.152'; # VERSION

our $deprecate = 0;
#   has 'games' => (
#       isa     => 'ArrayRef[Games::Go::AGA::DataObjects::Game]',
#       is      => 'rw',
#       default => sub { [] },
#   );
#   has 'byes'  => (
#       isa     => 'ArrayRef[Games::Go::AGA::DataObjects::Player]',
#       is      => 'rw',
#       default => sub { [] },
#   );
has filename => (           # store a filename here
    is => 'rw',
);
has table_number  => (      # assign table numbers from how many tables used so far
    isa     => \&isa_Int,
    is      => 'rw',
    lazy    => 1,
    default => sub { 1 },
);
has change_callback => (
    isa => \&isa_CodeRef,
    is => 'rw',
    lazy => 1,
    default => sub { sub {} },
);
has suppress_changes => (   # don't call change_callback if set
    is => 'rw',
    lazy => 1,
    default => sub { 0 }
);
has fprint_pending => (   # set when changed called, cleared after fprint done
    is => 'rw',
    lazy => 1,
    default => sub { 0 }
);
has round_num => (  # which round is this?
    isa => sub {
        die defined $_[0] ? "Invalid round index $_[0]" : "round index not defined" if (not is_Int($_[0]) or $_[0] < 1);
    },
    is => 'rw',
    lazy => 1,
    default => sub { 0 },
);
has adj_ratings_change => (  # set when player->adj_ratings need recalculation
    is => 'rw',
    lazy => 1,
    default => sub { 1 },
);
has id => (
    is => 'rw',
);
has id_len => (
    is => 'rw',
);
has handi_len => (
    is => 'rw',
);
has komi_len => (
    is => 'rw',
);
has name_len => (
    is => 'rw',
);

our $idxx = 0;

sub BUILD {
    my ($self) = @_;
    $self->{games} = [];
    $self->{byes}  = [];
    $self->id($idxx++);
}

sub changed {
    my ($self, @args) = @_;

    $self->fprint_pending(1);
    $self->adj_ratings_change(1);
    &{$self->change_callback}(@_) if (not $self->suppress_changes);
}

sub games {
    my ($self) = @_;

    return wantarray
        ? @{$self->{games}}
        : $self->{games};
}

# find game by index or by 1 or two IDs
sub game {
    my ($self, $which, $which2) = @_;

    if (@_ <= 2 and
        looks_like_number($which) and
        $which < @{$self->{games}} ) {
        return $self->{games}[$which];  # as index
    }
    $which  = normalize_ID($which);
    $which2 ||= $which;
    $which2 = normalize_ID($which2);
    for my $game (@{$self->{games}}) {
        my $wid = $game->white->id;
        my $bid = $game->black->id;
        if (($wid eq $which or $bid eq $which) and
            ($wid eq $which2 or $bid eq $which2)) {
            return $game;
        }
    }
    return; # not found
}

sub byes {
    croak("Rounds->byes is deprecated") if ($deprecate > 0);
    my ($self) = @_;

    return wantarray
        ? @{$self->{byes}}
        : $self->{byes};
}

sub add_game  {
    my ($self, $game) = @_;

    my $prev_callback = $game->change_callback;
    $game->change_callback( # add to game callback
        sub {
            $prev_callback->(@_);   # whatever happened before, and
            $self->changed;         #   our status changes
        }
    );
    push (@{$self->{games}}, $game);
    $game->table_number($self->table_number);
    $self->table_number($self->table_number + 1);
    $self->changed;
    return $self;
}

sub clear_table_number {
    my ($self) = @_;

    $self->table_number(1);
}

sub remove_game {
    my ($self, $game) = @_;

    my $games = $self->{games};
    if (ref $game) {    # if game is a ref, find index of that ref
        my $raddr = refaddr($game);
        for (my $idx = 0; $idx < @{$games}; $idx++) {
            if (refaddr($games->[$idx]) == $raddr) {
                $game = $idx;
                last;
            }
        }
        if (ref $game) {
            croak "Game not found";
        }
    }
    $game = splice @{$games}, $game, 1; # remove from our list
#   $self->add_bye($game->white);
#   $self->add_bye($game->black);
    $self->changed;   # add_bye already calls this
    return $game;
}

sub add_bye {
    croak("Rounds->add_bye is deprecated") if ($deprecate > 0);
    my ($self, $player) = @_;

    # check for duplicate IDs
    return $self if (grep { $_->id eq $player->id } @{$self->{byes}});
    push (@{$self->{byes}}, $player);
    $self->changed;
    return $self;
}

sub remove_bye {
    croak("Rounds->remove_bye is deprecated") if ($deprecate > 0);
    my ($self, $player) = @_;

    my $idx = $self->_find_bye_idx($player);      # convert to index
    my $removed = splice @{$self->{byes}}, $idx, 1;
    $self->changed;
    return $removed;
}

sub replace_bye {
    croak("Rounds->replace_bye is deprecated") if ($deprecate > 0);
    my ($self, $old_bye, $new_bye) = @_;

    my $idx = $self->_find_bye_idx($old_bye);      # convert to index
    my $removed = $self->{byes}[$idx];
    $self->{byes}[$idx] = $new_bye;
    $self->changed;
    return $removed;
}

sub swap {
    croak("Rounds->swap is deprecated") if ($deprecate > 0);
    my ($self, $id_0, $id_1) = @_;

    my ($p0, $p1, $opp0, $opp1, $item0, $item1);

    for my $player (@{$self->{byes}}) {
        if ($player->id eq $id_0) {
            $item0 = $player;
            $p0 = $player;
        }
        if ($player->id eq $id_1) {
            $item1 = $player;
            $p1 = $player;
        }
    }

    for my $game (@{$self->{games}}) {
        if    ($game->white->id eq $id_0) {
            $item0 = $game;
            $p0 = $game->white;
            $opp0 = $game->black;
        }
        elsif ($game->black->id eq $id_0) {
            $item0 = $game;
            $p0 = $game->black;
            $opp0 = $game->white;
        }
        if ($game->white->id eq $id_1) {
            $item1 = $game;
            $p1 = $game->white;
            $opp1 = $game->black;
        }
        elsif ($game->black->id eq $id_1) {
            $item1 = $game;
            $p1 = $game->black;
            $opp1 = $game->white;
        }
        last if (defined $item0 and defined $item1);
    };
    if (not defined $item0) {
        croak "ID $id_0 not found in games or Byes lists\n";
    }
    if (not defined $item1) {
        croak "ID $id_1 not found in games or Byes lists\n";
    }
    # no-op if both are Player IDs from Byes list
    return if ($item0->can('id') and $item1->can('id'));
    if ($item0->can('white') and $item1->can('white')) {
        # both items are Games.
        if ($item0->white->id eq $item1->white->id and
            $item0->black->id eq $item1->black->id) {   # same game?
            $item0->swap;       # just swap black and white players
        }
        else {
            # swap players between two games
            if ($p0->id eq $item0->white->id) {
                $item0->white($p1);
            }
            else {
                $item0->black($p1);
            }
            if ($p1->id eq $item1->white->id) {
                $item1->white($p0);
            }
            else {
                $item1->black($p0);
            }
        }
    }
    elsif ($item0->can('id')) {
        # first item is a Bye Player, second is a Game
        if ($p1->id eq $item1->white->id) {
            $item1->white($p0);
        }
        else {
            $item1->black($p0);
        }
        $self->replace_bye($p0, $p1);
    }
    elsif ($item1->can('id')) {
        # swap players between game and Byes list
        if ($p0->id eq $item0->white->id) {
            $item0->white($p1);
        }
        else {
            $item0->black($p1);
        }
        $self->replace_bye($p1, $p0);
    }
    $item0->handicap if ($item0->can('handicap'));
    $item1->handicap if ($item1->can('handicap'));
}

# find player in BYEs list
sub _find_bye_idx {
    croak("Rounds->_find_bye_idx is deprecated") if ($deprecate > 0);
    my ($self, $idx) = @_;

    my $players = $self->{byes};
    if (looks_like_number($idx)) {
        # already what we need
    }
    elsif (ref $idx) {      # must be a Player dataobject
        # find Player object with matching ID
        FIND_REFADDR : {
            my $player = $idx;
            my $id = $player->id;
            for my $ii (0 .. $#{$players}) {
                if ($players->[$ii]->id eq $id) {
                    $idx = $ii;
                    last FIND_REFADDR;
                }
            }
            croak "can't find BYE player with ID $id\n";
        }
    }
    else {
        # find Player with matching ID
        FIND_ID : {
            my $id = $idx;
            for my $ii (0 .. $#{$players}) {
                if ($players->[$ii]->id eq $id) {
                    $idx = $ii;
                    last FIND_ID;
                }
            }
            croak "can't find player matching ID $id\n";
        }
    }
    if ($idx < 0 or
        $idx > $#{$players}) {
        croak "index=$idx is out of bounds\n";
    }
    return $idx;
}

# format a string representing the player's rating adjustment this round
sub rating_adjustment {
    my ($self, $player, $round_num) = @_;

    my $rating     = sprintf '% 7.3f', Rank_to_Rating($player->rank);
    my $adj_rating = $player->adj_rating($round_num);
    $adj_rating = sprintf '% 7.3f', $adj_rating if ($adj_rating);
    if ($adj_rating and $adj_rating ne $rating) {
        return "$rating->$adj_rating";
    }
    return $rating;
}

sub measure_player_field_lengths {
    my ($self, $player) = @_;

    $self->id_len  (length $player->id)        if (length $player->id        > $self->id_len);
    $self->name_len(length $player->full_name) if (length $player->full_name > $self->name_len);
}

sub measure_field_lengths {
    my ($self) = @_;

    $self->id_len(0);
    $self->handi_len(0);
    $self->komi_len(0);
    $self->name_len(0);
    for my $game (@{$self->{games}}) {
        $self->measure_player_field_lengths($game->white);
        $self->measure_player_field_lengths($game->black);
        $self->handi_len(length $game->handi) if (length $game->handi > $self->handi_len);
        $self->komi_len (length $game->komi)  if (length $game->komi  > $self->komi_len);
    }
if ($deprecate == 0) {
    for my $bye (@{$self->{byes}}) {
        $self->measure_player_field_lengths($bye);
    }
}
}

sub fprint {
    my ($self, $fh) = @_;

    my $round_num = $self->round_num;
    $fh->print("# Round $round_num\n\n");

    $self->measure_field_lengths;
    for my $game (@{$self->{games}}) {
        my $w = $game->white;
        my $b = $game->black;
        my $result = '?';
        my $winner = $game->winner;
        if ($winner) {
            $result = 'w' if ($winner->id eq $w->id);
            $result = 'b' if ($winner->id eq $b->id);
        }

        $fh->printf("%*s %*s %s %*s %*s # %*s (%s) vs (%s) %*s\n",
            $self->id_len, $w->id,
            $self->id_len, $b->id,
            $result,
            $self->handi_len, $game->handi,
            $self->komi_len, $game->komi,
            $self->name_len, $w->full_name,
            $self->rating_adjustment($w, $round_num),
            $self->rating_adjustment($b, $round_num),
            $self->name_len, $b->full_name,
        );
    }
    for my $bye (@{$self->{byes}}) {
        $fh->printf("# BYE: %s  %s, %s\n",
            $bye->id,
            $bye->last_name,
            $bye->first_name,
        );
    }
    $self->fprint_pending(0);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::DataObjects::Round - model a round of an AGA tournament

=head1 VERSION

version 0.152

=head1 SYNOPSIS

    use Games::Go::AGA::DataObjects::Round;
    my $round = Games::Go::AGA::DataObjects::Round->new;

=head1 DESCRIPTION

A Games::Go::AGA::DataObjects::Round models the information in a tournament
round.  There is a list of pairings and a list of BYE players (not playing
this round).

NOTE: The BYEs list here is DEPRECATED: byes are handled at the Tournament level now.

=head1 METHODS

=head2 my $round = Games::Go::AGA::DataObjects::Round->new();

Creates a new B<Round> object.

=head2 my $games_ref = $round->games;

Returns a reference to a copy of the games list.  Since this is a copy,
games cannot be added or removed by changing this list.

=head2 my $byes_ref = $round->byes;

DEPRECATED: byes are handled at the Tournament level now.

Returns a reference to a copy of the byes list.  Since this is a copy,
byes cannot be added or removed by changing this list.

=head2 $round->add_game($game);

Adds a Games::Go::AGA::DataObjects::Game to the Round.  The game is also
added to each Games::Go::AGA::DataObjects::Player's games list.   The
number of tables (B<table_number>) in the round is incremented, and
B<$game-E<gt>table_number> is set to the new number.

=head2 $round->clear_table_number;

Normally, B<table_number> is incremented for each added game and is never
decremented.  Games don't 'give up' their numbers, which could cause
confusion.

For a round that is being re-paired, call B<clear_table_number> to reset
the number back to the start.

=head2 $round->remove_game($game);

Removes a Games::Go::AGA::DataObjects::Game to the Round and from each
Games::Go::AGA::DataObjects::Player's games list.  B<$game> can also be an
index into the B<games> array.  The players from the removed game are
transferred to the B<byes> array.  Can die if game is not found.

=head2 $round->add_bye($player);

DEPRECATED: byes are handled at the Tournament level now.

Adds a Games::Go::AGA::DataObjects::Player as a BYE.

=head2 $round->remove_bye($player);
DEPRECATED: byes are handled at the Tournament level now.

Removes a Games::Go::AGA::DataObjects::Player from the B<byes> list.
B<$player> can be an ID or an index into the B<byes> list.  The
Games::Go::AGA::DataObjects::Player is returned.  Can die if the player is
not found.

=head2 $round->replace_bye($old_player, $new_player);
DEPRECATED: byes are handled at the Tournament level now.

Removes B<$old_player> from the B<byes> list and replaces him with
B<$new_player>.  B<$old_player> can be an ID or an index into the B<byes>
list.  The Games::Go::AGA::DataObjects::Player for B<$old_player> is
returned.  Can die if the B<$old_player> is not found.

=head2 $round->swap($id_0, $id_1);

Swap two players.  The two players may both be in a game, or one (but not
both) may be in the B<byes> list.

Throws an exception if either player is not found.  If both are in the
B<byes> list, nothing happens.

=head1 ACCESSORS

Accessor methods are defined for the following attributes:

=over 8

=item games     the array of games

=item byes      the array of BYE players

=back

=head1 SEE ALSO

=over 4

=item Games::Go::AGA

=item Games::Go::AGA::DataObjects

=item Games::Go::AGA::Parse

=item Games::Go::AGA::Gtd

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
