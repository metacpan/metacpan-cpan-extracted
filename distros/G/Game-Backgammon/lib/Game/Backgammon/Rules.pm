package Game::Backgammon::Rules;

use strict;
use warnings;

use Game::Backgammon::Board;
use Game::Backgammon::Move;
use Game::Backgammon::Turn;
use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(legal_turns apply_move single_moves);

sub single_moves {
    my ($board, $player, $die) = @_;
    my @out;

    if ($board->bar($player)) {
        my $to = 25 - $die;
        return () if $board->is_blocked($player, $to);
        return Game::Backgammon::Move->new(
            player => $player, from => 'bar', to => $to, die => $die,
            hit => $board->is_blot($player, $to));
    }

    my $home = $board->all_home($player);
    my $highest = $home ? $board->highest_occupied($player) : 0;

    for my $n (1 .. 24) {
        next unless $board->mine_on($player, $n);
        my $to = $n - $die;

        if ($to >= 1) {
            next if $board->is_blocked($player, $to);
            push @out, Game::Backgammon::Move->new(
                player => $player, from => $n, to => $to, die => $die,
                hit => $board->is_blot($player, $to));
            next;
        }

        next unless $home;
        if ($to == 0) {
            push @out, Game::Backgammon::Move->new(
                player => $player, from => $n, to => 'off', die => $die);
        }
        elsif ($n == $highest) {
            push @out, Game::Backgammon::Move->new(
                player => $player, from => $n, to => 'off', die => $die);
        }
    }
    return @out;
}

sub apply_move {
    my ($board, $move) = @_;
    my $next = $board->clone;
    my $player = $move->player;
    my $them = Game::Backgammon::Board::other($player);

    if ($move->is_bar) { $next->to_bar($player, -1) }
    else               { $next->add($player, $move->from, -1) }

    if ($move->is_off) { $next->to_off($player) }
    else {
        if ($next->is_blot($player, $move->to)) {
            $next->set_point($them, 25 - $move->to, 0);
            $next->to_bar($them);
        }
        $next->add($player, $move->to, 1);
    }
    return $next;
}

sub legal_turns {
    my ($board, $player, @dice) = @_;

    my @seqs;
    _walk($board, $player, \@dice, [], \@seqs);

    my $most = 0;
    for my $s (@seqs) { $most = @{ $s->{moves} } if @{ $s->{moves} } > $most }
    @seqs = grep { @{ $_->{moves} } == $most } @seqs;

    if ($most == 1 && @dice == 2 && $dice[0] != $dice[1]) {
        my $larger = $dice[0] > $dice[1] ? $dice[0] : $dice[1];
        my @big = grep { $_->{moves}[0]->die == $larger } @seqs;
        @seqs = @big if @big;
    }

    return [ Game::Backgammon::Turn->new(player => $player, dice => \@dice, moves => []) ]
        unless @seqs;

    my (%seen, @turns);
    for my $s (@seqs) {
        my $turn = Game::Backgammon::Turn->new(
            player => $player, dice => \@dice, moves => $s->{moves});
        next if $seen{ $turn->key }++;
        push @turns, $turn;
    }
    return \@turns;
}

sub _walk {
    my ($board, $player, $dice, $sofar, $out) = @_;
    push @$out, { moves => [ @$sofar ] };
    return unless @$dice;

    my %tried;
    for my $i (0 .. $#$dice) {
        next if $tried{ $dice->[$i] }++;
        my @rest = @$dice;
        my ($die) = splice @rest, $i, 1;
        for my $move (single_moves($board, $player, $die)) {
            _walk(apply_move($board, $move), $player, \@rest,
                  [ @$sofar, $move ], $out);
        }
    }
    return;
}

1;

__END__

=head1 NAME

Game::Backgammon::Rules - the legal turn

=head1 SYNOPSIS

    use Game::Backgammon::Rules qw(legal_turns);

    my $turns = legal_turns($board, 'white', 3, 1);
    $_->notation for @$turns;          # '8/5 6/5', '24/21 6/5', ...

=head1 DESCRIPTION

A turn in backgammon is a set of moves, not a move, and two of the rules
binding it are properties of the whole set:

=over

=item * both dice must be played if any legal sequence plays both;

=item * if only one can be played, and either could be alone, the larger
must be.

=back

Neither can be applied one die at a time: a move that looks legal on its own
can be the one that makes the other die unplayable, and then it never was.
So C<legal_turns> enumerates every sequence, keeps the longest, applies the
larger-die rule to what is left, and deduplicates by the multiset of moves,
because two orders reaching the same position are one choice.

A player who can do nothing gets exactly one turn back, an empty one. A
forfeit is a turn, not an error.

=head2 Cost

Bounded: at most two dice from at most fifteen sources, or four on doubles.
The worst realistic case is a doubles roll in a crowded position, which is a
few hundred sequences. That is fine here and is the number the bot has to
budget for.

=head1 FUNCTIONS

=head2 legal_turns($board, $player, @dice)

Every distinct legal turn, as L<Game::Backgammon::Turn> objects. Always at
least one: a player who can do nothing gets an empty turn.

=head2 single_moves($board, $player, $die)

Where one checker may go with one die. A building block of the enumeration
above, and not a legal move on its own: only a whole turn is legal.

=head2 apply_move($board, $move)

The board that results, as a new object. Never changes the one it is given.

=cut
