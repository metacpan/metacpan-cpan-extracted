package Game::Gin;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Gin::Deal ();
use Game::Gin::Error ();
use Game::Gin::Scoring qw(match_result TARGET);

our $VERSION = '0.01';

has seed    => (is => 'ro', isa => Str);
has target  => (is => 'ro', isa => Int);
has dealer  => (is => 'rw', isa => Str);
has deal    => (is => 'rw', isa => Object);
has number  => (is => 'rw', isa => Int);
has hands   => (is => 'rw', isa => ArrayRef);
has result  => (is => 'rw', isa => HashRef);

sub build {
    my ($class, %o) = @_;
    my $seed = $o{seed};
    return Game::Gin::Error->new_code('no_seed')
        unless defined $seed && length $seed == 32;

    my $dealer = $o{dealer} || 'p1';
    my $self = $class->new(
        seed   => $seed,
        target => $o{target} || TARGET,
        dealer => $dealer,
        number => 1,
        hands  => [],
        deal   => Game::Gin::Deal->build(seed => $seed, number => 1, dealer => $dealer),
        result => undef,
    );
    return $self;
}

sub over  { return $_[0]->result ? 1 : 0 }
sub turn  { my $s = $_[0]; return undef if $s->over; return $s->deal->turn }
sub legal { my ($s, $seat) = @_; return [] if $s->over; return $s->deal->legal($seat) }

sub scores {
    my ($self) = @_;
    my %p = (p1 => 0, p2 => 0);
    for my $h (@{ $self->hands }) {
        next unless $h->{winner};
        $p{ $h->{winner} } += $h->{points};
    }
    return \%p;
}

sub apply {
    my ($self, $seat, $move) = @_;
    return Game::Gin::Error->new_code('hand_over') if $self->over;

    my @out = $self->deal->apply($seat, $move);
    return $out[0] if @out == 1 && ref $out[0] eq 'Game::Gin::Error';

    return @out unless $self->deal->over;

    my $r = $self->deal->result;
    push @{ $self->hands }, { %$r, number => $self->number };

    my $scores = $self->scores;
    if (($scores->{p1} >= $self->target) || ($scores->{p2} >= $self->target)) {
        my $m = match_result(hands => $self->hands, target => $self->target);
        $self->result($m);
        push @out, { kind => 'game_end', %$m };
        return @out;
    }

    $self->dealer($r->{winner}) if $r->{winner};
    $self->number($self->number + 1);
    $self->deal(Game::Gin::Deal->build(
        seed => $self->seed, number => $self->number, dealer => $self->dealer));
    push @out, { kind => 'deal', number => $self->number, dealer => $self->dealer };
    return @out;
}

1;

__END__

=head1 NAME

Game::Gin - gin rummy as a reusable engine

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Gin;

    my $game = Game::Gin->build(seed => $thirty_two_bytes, dealer => 'p1');

    $game->turn;                 # 'p2', the non-dealer has the first say
    $game->legal('p2');          # take or pass

    my @out = $game->apply('p2', { kind => 'take' });
    @out = $game->apply('p2', { kind => 'discard', card => $id, knock => 1 });

    $game->scores;               # { p1 => 41, p2 => 12 }
    $game->over;                 # 1 once somebody reaches the target
    $game->result->{winner};

=head1 DESCRIPTION

Two-handed gin rummy, played over many deals to 100 points.

The engine does no input and no output: it never prints, never reads a handle
and never calls C<rand>. A match is a pure function of its seed and its moves,
so a finished game can be replayed and checked by anybody once the seed is
published. L<Game::Gin::Terminal> is the only part of this distribution that
touches a handle.

It is the engine behind the gin rummy at L<https://peer2peergames.com>.

=head2 Which ruleset this is

The modern set, as Wikipedia states it: knock at ten, gin 25, undercut 25, big
gin 31, box bonus 25 a hand, game bonus 100, target 100. The older published
set, which Pagat gives and Wikipedia calls the early official rules, is gin 20
and undercut 10. They are two rulesets rather than two opinions, and taking a
number from each would produce scoring no publication describes.

=head2 The player who reaches the target wins

The bonuses decide the margin, not the winner. A player who wins many small
hands can finish with a higher total than the player who won the game, and
still not have won it. See L<Game::Gin::Scoring/match_result>.

=head2 The winner of a hand deals the next

Pagat's standard rule. Two variations exist and are not implemented: that the
loser deals, and that the deal alternates. After a cancelled hand, which no
source covers, the dealer deals again.

=head1 METHODS

=head2 build

    Game::Gin->build(seed => $bytes, dealer => 'p1', target => 100);

Starts a match. Returns the game, or a L<Game::Gin::Error> for a bad seed.

=head2 legal

The moves a seat may make now, delegated to the current deal.

=head2 apply

    $game->apply($seat, $move);

Applies a move. Returns the outcomes, or a L<Game::Gin::Error>. When a deal
ends, the outcomes carry a C<hand_end> and then either a C<deal> for the next
one or a C<game_end>.

=head2 scores

The running hand points, without bonuses. This is what decides when the match
ends.

=head2 turn, over, result, deal, hands, number, dealer, seed, target

Where the match is. C<deal> is the current L<Game::Gin::Deal>, C<hands> the
results of the finished ones, and C<result> the match result once it is over.

=head1 SEE ALSO

L<Game::Gin::Deal>, L<Game::Gin::Scoring>, L<Game::Gin::Deadwood>,
L<Game::Gin::Meld>, L<Game::Gin::Deck>, L<Game::Gin::Card>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
