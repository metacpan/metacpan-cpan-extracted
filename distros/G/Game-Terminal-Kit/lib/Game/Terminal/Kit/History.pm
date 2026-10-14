package Game::Terminal::Kit::History;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar -types;
use State::Store;

our $VERSION = '0.05';

has [qw/save load/] => (
	is => 'rw',
	isa => CodeRef
);

has limit => (
	is => 'rw',
	isa => Int,
	default => 200
);

has store => (
	is => 'rw'
);

has begun => (
	is => 'rw',
	isa => Bool,
	default => 0
);

sub BUILD {
	my ($self) = @_;
	Carp::croak('Game::Terminal::Kit::History: save and load are both needed')
		unless $self->save && $self->load;
	$self->store(State::Store->new(undef, history => $self->limit > 0 ? $self->limit : undef))
		unless $self->store;
	return $self;
}

sub _snapshot {
	my ($self, $game) = @_;
	my $text = $self->save->($game);
	Carp::croak('Game::Terminal::Kit::History: save gave ' . (defined $text ? 'a reference' : 'nothing')
		. ' for ' . (ref $game || 'a game') . ', where a string is needed')
		if !defined $text || ref $text;
	return $text;
}

sub start {
	my ($self, $game) = @_;
	$self->store->set($self->_snapshot($game));
	$self->store->clear_history;
	$self->begun(0);
	return $self;
}

sub record {
	my ($self, $game) = @_;
	$self->store->set($self->_snapshot($game));
	return $self;
}

sub turn {
	my ($self, $game) = @_;
	return $self->record($game) if $self->begun;
	$self->start($game);
	$self->begun(1);
	return $self;
}

sub text {
	my ($self) = @_;
	return $self->store->current;
}

sub undo {
	my ($self, $steps) = @_;
	return undef unless $self->store->undo(defined $steps ? $steps : 1);
	return $self->_rebuild;
}

sub redo {
	my ($self, $steps) = @_;
	return undef unless $self->store->redo(defined $steps ? $steps : 1);
	return $self->_rebuild;
}

sub _rebuild {
	my ($self) = @_;
	my $game = $self->load->($self->store->current);
	Carp::croak('Game::Terminal::Kit::History: load gave nothing back for a saved game')
		unless defined $game;
	return $game;
}

sub can_undo { return $_[0]->store->can_undo ? 1 : 0 }

sub can_redo { return $_[0]->store->can_redo ? 1 : 0 }

sub undo_count { return $_[0]->store->undo_count }

sub redo_count { return $_[0]->store->redo_count }

sub clear {
	my ($self) = @_;
	$self->store->clear_history;
	return $self;
}

sub game_keys {
	return { u => 'undo', r => 'redo' };
}

sub legend {
	my ($self) = @_;
	return join ', ', ($self->can_undo ? 'u undo' : ()), ($self->can_redo ? 'r redo' : ());
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::History - take a turn back, and play it again

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::History;

    my $history = Game::Terminal::Kit::History->new(
        save => sub { my ($game) = @_; $game->to_text },
        load => sub { my ($text) = @_; Game::Reversi->from_text($text) },
    );

    $history->start($game);

    while (!$game->over) {
        $history->turn($game) if $self->is_person($game->turn);
        ...
        if ($key eq 'u' and my $earlier = $history->undo) {
            $self->game($earlier);
        }
        if ($key eq 'r' and my $later = $history->redo) {
            $self->game($later);
        }
    }

=head1 DESCRIPTION

Undo and redo for a game played at a terminal, kept in a L<State::Store>.

=head2 What is kept

The game itself is never kept: a game engine changes as it is played, and a
version kept in a history must not. What is kept is the game written as a
string by C<save>, and what comes back from L</undo> and L</redo> is a new
game built from that string by C<load>. A string cannot change once kept,
and a string the same as the last one kept is no change, so recording a game
nobody has moved makes no step.

C<save> must write everything the game needs to play on as it would have:
the position, whose turn it is, the moves where a rule depends on them, and
the seed and counters its dice and deals come from. C<load> must build a game
that C<save> writes the same string for.

=head2 What a step is

A step is whatever the game records between two calls of L</record>. A game
records when the turn passes to the person at the keys, so one undo takes
back that person's move and every reply the program made to it. In a game
two people play at one keyboard, every move is a step.

A move made after an undo throws away what could have been redone.

=head1 ATTRIBUTES

=head2 save

A code reference given the game and returning it as a string. Needed.

=head2 load

A code reference given a string from C<save> and returning a new game.
Needed.

=head2 limit

The most steps kept to undo; 200 by default. The oldest is forgotten when
one more is made. 0 keeps every step.

=head2 store

The L<State::Store> underneath, made in C<new> unless one is given.

=head1 METHODS

=head2 start

    $history->start($game);

The game as it starts, or as it is when loaded: it becomes the current
version, and there is nothing to undo or redo. Returns the history.

=head2 record

    $history->record($game);

The game as it is now, as a new step, unless it is the same as the last one
kept. Returns the history. Dies naming the game's class when C<save> gives
back anything but a string.

=head2 undo

    my $game = $history->undo;
    my $game = $history->undo($steps);

A new game, built as it was one step back, or that many steps back, or as far
back as there is; undef when there is no step to take. Only one game is
built, however many steps are taken. Dies when C<load> gives back
nothing, rather than look like a history with no step to take: a C<load> that
returns a list must be called so that the game comes first.

=head2 redo

    my $game = $history->redo;
    my $game = $history->redo($steps);

The same, forwards again.

=head2 can_undo

=head2 can_redo

=head2 undo_count

=head2 redo_count

Whether there is a step to take back or forward, and how many.

=head2 turn

    $history->turn($game);

What a game calls when the turn passes to the person at the keys. The first
call after L</start> makes that position the beginning, so a move the program
made before the person had a turn is never a step to take back; every later
call is L</record>. Returns the history.

=head2 begun

True once L</turn> has been called since L</start>.

=head2 text

The current version, as the string C<save> wrote.

=head2 clear

Forgets every step both ways and keeps the current version. Returns the
history.

=head2 game_keys

    my $picker = Game::Terminal::Kit::Picker->new(
        game_keys => { %{ $history->game_keys }, '?' => 'help' },
        ...
    );

C<u> for undo and C<r> for redo, as a hash reference for a picker.

=head2 legend

    'u undo, r redo'

The keys that do something now, for the line under a board: empty at the
start of a game, C<u undo> once there is a step, and C<r redo> after one has
been taken back.

=head1 SEE ALSO

L<State::Store>, L<Game::Terminal::Kit>, L<Game::Terminal::Kit::Picker>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
