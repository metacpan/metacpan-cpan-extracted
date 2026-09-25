package Game::Mahjong::Bot;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Digest::SHA ();
use Game::Mahjong::Search;

our $VERSION = '0.01';

our @LADDER = (1, 2, 3, 3);

has level => (is => 'ro', isa => Int, default => 2);

has seed => (is => 'ro', isa => Str, default => 'mahjong-bot');

sub BUILD {
	my ($self) = @_;
	my $level = $self->level;
	die "Game::Mahjong::Bot: level must be 1 to 3, not '$level'"
		unless $level >= 1 && $level <= 3;
	return;
}

sub levels { return (1 .. 3) }

sub choose {
	my ($self, $rules, $seat) = @_;
	return undef unless grep { $_ == $seat } $rules->waiting_on;
	my $view = Game::Mahjong::Search::view_of($rules, $seat);
	$view->{seed} = $self->seed . ':' . $seat;
	return Game::Mahjong::Search::best($view, $self->level);
}

sub hint {
	my ($self, $rules, $seat) = @_;
	return undef unless grep { $_ == $seat } $rules->waiting_on;
	my $view = Game::Mahjong::Search::view_of($rules, $seat);
	$view->{seed} = $self->seed . ':' . $seat;
	return Game::Mahjong::Search::best($view, $LADDER[-1]);
}

1;

__END__

=head1 NAME

Game::Mahjong::Bot - a seat played by the machine, at a level

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $bot = Game::Mahjong::Bot->new(level => 2, seed => $seed);
    my $move = $bot->choose($rules, $seat);   # undef when the seat is not waited on
    my $hint = $bot->hint($rules, $seat);     # the top rung's move

=head1 DESCRIPTION

Three levels, L<Game::Mahjong::Search>'s rungs. C<choose> answers undef
for a seat that is not waited on, so a driver that loops over the waited
seats reads undef as "stop", and every move it returns is one of the seat's
legal moves, so the rules never refuse it. Ties are broken from the seed
with the seat mixed in, so four bots at one table sharing a game seed do
not all break the same tie the same way.

=head1 ATTRIBUTES

=head2 level

1 to 3.

=head2 seed

A string; the game's seed, usually.

=head1 METHODS

=head2 choose

The move for a seat now, or undef.

=head2 hint

The top rung's move for a seat now, whatever this bot's level.

=head2 levels

1, 2, 3.

=head2 @LADDER

The bag a site draws a rung from, weakest first. A rung may appear more
than once; that is the weighting.

=head2 The ladder, measured

One seat of the higher rung against three of the rung below, the measured
seat rotating, a hundred games a pairing (C<xt/ladder.t>, 24 September
2026):

    rung 2 against three rung 1s    +216.0 points a game   87 games in 100
    rung 3 against three rung 2s      +6.8 points a game   24 games in 100
    rung 3 against three rung 1s    +202.7 points a game   86 games in 100

And the two ideas rung 3 adds, each switched off in turn against three full
rung 3s:

    without the defence               +7.9 points a game   24 games in 100
    without the pattern target        +9.3 points a game   26 games in 100

B<Rung 2 carries this ladder.> Rung 3's two ideas are worth nothing a
hundred games can distinguish from chance, which is a quarter of the games
at four seats. The bag still ends in 3, because C<hint> reaches for the last
rung and the defence costs nothing to run; a stronger third rung is work
left undone rather than work done.

=head1 SEE ALSO

L<Game::Mahjong::Search>, L<Game::Mahjong::Rules>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
