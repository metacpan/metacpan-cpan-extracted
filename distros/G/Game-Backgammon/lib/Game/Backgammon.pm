package Game::Backgammon;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Backgammon::Board;
use Game::Backgammon::Dice ();
use Game::Backgammon::Move;
use Game::Backgammon::Notation ();
use Game::Backgammon::Result;
use Game::Backgammon::Rules ();
use Game::Backgammon::Turn;

our $VERSION = '0.01';

has seed => (
	is => 'ro',
	isa => Str
);

has board => (
	is => 'rw',
	isa => Object,
	default => sub { Game::Backgammon::Board->new }
);

has turn => (
	is => 'rw',
	isa => Str
);

has rolls => (
	is => 'rw',
	isa => Int,
	default => 0
);

has pending => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

has history => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

has result => (
	is => 'rw',
	isa => Any
);

sub BUILD {
	my ($self) = @_;
	return if $self->turn;
	my ($first, $dice, $used) = Game::Backgammon::Dice::opening_for($self->seed);
	$self->turn($first);
	$self->rolls($used);
	$self->pending([ sort { $b <=> $a } @$dice ]);
	return;
}

sub status { return $_[0]->result ? 'finished' : 'active' }

sub other { return $_[0] eq 'white' ? 'black' : 'white' }

sub dice {
	my ($self) = @_;
	return [] if $self->result;
	return [ @{ $self->pending } ] if @{ $self->pending };
	my @dice = Game::Backgammon::Dice::dice_for($self->seed, $self->rolls);
	$self->pending(\@dice);
	return [ @dice ];
}

sub legal_turns {
	my ($self) = @_;
	return [] if $self->result;
	return Game::Backgammon::Rules::legal_turns($self->board, $self->turn, @{ $self->dice });
}

sub play {
	my ($self, $which) = @_;
	return _refuse('game_over') if $self->result;

	my $legal = $self->legal_turns;
	my $want;
	if (ref $which) { $want = $which }
	else {
		$want = Game::Backgammon::Notation::parse_turn($which, player => $self->turn)
			or return _refuse('not_notation', $@);
	}

	my ($turn) = grep { $_->key eq $want->key } @$legal;
	return _refuse('not_legal') unless $turn;

	my $board = $self->board;
	$board = Game::Backgammon::Rules::apply_move($board, $_) for @{ $turn->moves };
	$self->board($board);
	push @{ $self->history }, $turn;

	$self->rolls($self->rolls + 1);
	$self->pending([]);

	return $turn if $self->_check_finished;
	$self->turn(other($self->turn));
	return $turn;
}

sub _check_finished {
	my ($self) = @_;
	for my $player (qw(white black)) {
		next unless $self->board->off($player) == Game::Backgammon::Board::CHECKERS;
		$self->result(Game::Backgammon::Result->new(
			winner => $player,
			margin => Game::Backgammon::Result->margin_for($self->board, $player),
			reason => 'borne_off'));
		return 1;
	}
	return 0;
}

sub finish {
	my ($self, %o) = @_;
	return _refuse('game_over') if $self->result;
	my $reason = $o{reason} // 'resign';
	$self->result(Game::Backgammon::Result->new(
		winner => $o{winner}, margin => $o{margin} // 'single', reason => $reason));
	return $self->result;
}

sub replay {
	my ($class, %o) = @_;
	my $self = $class->new(seed => $o{seed});
	for my $line (@{ $o{turns} || [] }) {
		my $played = $self->play($line);
		unless ($played) {
			my $err = $@;
			die 'Game::Backgammon: the log does not replay at turn '
			  . (scalar @{ $self->history } + 1) . ': '
			  . (ref $err ? $err->message : $err) . "\n";
		}
	}
	return $self;
}

sub to_log { return [ map { $_->notation } @{ $_[0]->history } ] }

sub _refuse {
	my ($code, $extra) = @_;
	require Game::Backgammon::Error;
	$@ = Game::Backgammon::Error->new(code => $code, detail => $extra);
	return undef;
}

1;

__END__

=head1 NAME

Game::Backgammon - backgammon as a reusable engine

=head1 SYNOPSIS

    use Game::Backgammon;

    my $game = Game::Backgammon->new(seed => $bytes);
    $game->turn;                       # who the opening roll sent first
    $game->dice;                       # [5, 2], from the seed

    for my $turn (@{ $game->legal_turns }) { print $turn->notation, "\n" }
    $game->play('8/3 6/4') or die $@;

    $game->status;                     # 'active' or 'finished'
    $game->result->margin;             # 'single', 'gammon', 'backgammon'

=head1 DESCRIPTION

Pure rules: no input, no output, no clock, and no randomness beyond the
seed. A game is its seed plus the turn chosen at each roll, and L</replay>
rebuilds it from exactly that.

It is the engine behind the backgammon at L<https://peer2peergames.com>.

=head2 A turn is the unit

Two dice mean up to two checkers move and doubles mean four, and the rules
binding which combinations are legal are properties of the whole set. So
C<legal_turns> offers whole turns and C<play> takes one. See
L<Game::Backgammon::Rules>.

=head2 The dice are checkable but not predictable

Roll C<n> is C<SHA-256($seed . "roll:$n:...")>, so a finished game can be
replayed and verified from its seed, while somebody who learns the seed
mid-game learns nothing about what is coming. See L<Game::Backgammon::Dice>.

=head2 No doubling cube, and no draws

There is no cube: it is not a wager, but it reads like one, and leaving it
out costs the game little. Backgammon cannot be drawn, so a result always
has a winner.

=head1 METHODS

=head2 new(seed => $bytes)

The opening roll decides who starts and gives them their dice.

=head2 dice, legal_turns, play($turn_or_notation)

=head2 status, result, turn, board, history, to_log

=head2 seed

The 32 bytes every roll is derived from.

=head2 rolls

How many rolls the game has consumed: the dice index replay needs.

=head2 pending

The dice rolled and not yet played.

=head2 other

The other player's name.

=head2 finish(winner => ..., reason => ...)

A finish imposed from outside: a resignation, a timeout, an abandoned game.
A resignation concedes a single.

=head2 replay(seed => ..., turns => [ '8/5 6/5', ... ])

=head1 SEE ALSO

L<Game::Backgammon::Board>, L<Game::Backgammon::Rules>,
L<Game::Backgammon::Dice>, L<Game::Backgammon::Result>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
