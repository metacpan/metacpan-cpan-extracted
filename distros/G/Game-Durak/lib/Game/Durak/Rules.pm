package Game::Durak::Rules;

use strict;
use warnings;

use Exporter 'import';

use Game::Durak::Card qw(rank_of beats);
use Game::Durak::Deck qw(HAND_SIZE);

our $VERSION = '0.01';
our @EXPORT_OK = qw(cap_for legal_attacks legal_beats forced closes);

sub cap_for {
    my ($size) = @_;
    die "cap_for wants a hand size\n"
        unless defined $size && $size =~ /\A[0-9]+\z/;
    return $size < HAND_SIZE ? $size : HAND_SIZE;
}

sub legal_attacks {
    my ($hand, $bout) = @_;
    return [] if $bout->room < 1;
    return [ @$hand ] unless $bout->size;
    my $ranks = $bout->ranks;
    return [ grep { $ranks->{ rank_of($_) } } @$hand ];
}

sub legal_beats {
    my ($hand, $bout, $trump) = @_;
    my $att = $bout->unbeaten;
    return [] unless defined $att;
    return [ grep { beats($_, $att, $trump) } @$hand ];
}

sub forced {
    my ($hand, $bout, $trump, $phase, $can_swap) = @_;
    return 0 if $can_swap;
    return @{ legal_beats($hand, $bout, $trump) }   ? 0 : 1 if $phase eq 'defend';
    return @{ legal_attacks($hand, $bout) }         ? 0 : 1;
}

sub closes {
    my ($bout, $defender_size) = @_;
    return undef if $bout->taken;
    return undef unless $bout->size && $bout->all_beaten;
    return 'spent'  unless $defender_size;
    return 'capped' if $bout->room < 1;
    return undef;
}

1;

__END__

=head1 NAME

Game::Durak::Rules - what may be played, as arithmetic over a hand and a bout

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Durak::Rules qw(cap_for legal_attacks legal_beats forced closes);

    my $cap = cap_for(scalar @{ $hand });        # min(6, the hand)

    legal_attacks($hand, $bout);                 # ids that may be thrown in
    legal_beats($hand, $bout, 'H');              # ids that beat the open card
    forced($hand, $bout, 'H', 'defend', 0);      # 1 if there is nothing to decide
    closes($bout, scalar @{ $defender_hand });   # 'capped', 'spent' or undef

=head1 DESCRIPTION

Functions over a hand, a bout and a trump suit. Nothing here takes a game, the
talon, the other hand or the seed, so nothing here can be written into a
position it was not given, and the bot's search can be handed the same
functions as the rules without handing it the deal.

=head2 legal_attacks does not take the trump

Which card may be thrown in is a question about rank alone, and the trump does
not enter it. The signature says so, which is cheaper than a comment and
harder to ignore: a reading of the rules that lets the trump matter here has
nowhere to put it.

=head2 forced, and why it asks about the exchange

    A TURN WITH NO CHOICE COSTS NOBODY A DEADLINE.
        -- lib/P2PGames/Game/Dominoes.pm, the site this engine feeds

An attacker with no legal throw is not deciding anything when they say they
are done, and a defender who cannot beat the card in front of them is not
deciding anything when they pick it up. The engine resolves both itself, and
neither costs a move, an event or a turn.

B<The exchange is why C<forced> takes a fifth argument.> The holder of the
trump six may swap it for the turned up trump, which can turn a hand that
cannot beat into one that can, and can hand the attacker a rank that is
already on the table. A position with a swap available is not forced, and an
engine that resolves it anyway steals the one move the exchange exists for.
The argument is a plain boolean because the eligibility is a provenance the
game object tracks and not something a hand can be asked.

=head2 closes is only the two answers nobody chooses

The rules give three ways a defence is beaten off:

    the defender has beaten all the attack cards played so far, and none of
    the defender's opponents is able and willing to continue the attack; the
    defender succeeds in beating six attacking cards; the defender (having
    begun the defence holding fewer than six cards) has no cards left in hand

The second and third are facts about the table, and they are what C<closes>
answers: C<capped> and C<spent>. The first is a decision ("willing") or a
forced position ("able"), so it belongs to C<forced> and to the C<done> move,
and C<closes> returns undef for it.

B<The third condition is tested first, and that is not an accident.> The cap
is the defender's hand before the bout when that is under six, and the
defender spends exactly one card per attack card beaten, so a defender who
started with fewer than six empties their hand on the same card that reaches
the cap: the two conditions fire together and never apart. Asked in the other
order, C<spent> would be dead code and every such bout would be reported as
C<capped>, which is true of the count and says nothing about what happened.
Asked in this order the two are distinct and both are reachable: C<spent> is
a defender with nothing left, and C<capped> is six cards against a defender
who still holds some.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 cap_for

The most cards an attack may hold against a hand of that size: the hand, or
six, whichever is smaller. Call it with the defender's hand B<before> the
bout, once, and keep the answer.

=head2 legal_attacks

The cards of the hand that may be played into the bout: every card while the
bout is empty, otherwise every card whose rank is already on the table,
answers included. Empty once the cap is reached.

=head2 legal_beats

The cards of the hand that beat the open attack card. Empty when nothing is
waiting to be beaten.

=head2 forced

True when the seat on turn has no choice at all: no legal move of the kind the
stage calls for, and no exchange available. The caller resolves the position
itself rather than asking.

=head2 closes

C<capped> when the attack has reached its cap with everything beaten,
C<spent> when the defender has beaten everything and has nothing left, and
undef otherwise. A taken bout is never closed by this function: the attacker
may still throw more in.

=head1 SEE ALSO

L<Game::Durak>, L<Game::Durak::Bout>, L<Game::Durak::Card>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
