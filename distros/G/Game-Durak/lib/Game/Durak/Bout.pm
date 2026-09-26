package Game::Durak::Bout;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Durak::Card ();

our $VERSION = '0.01';

has attacker => (is => 'ro', isa => Int);
has defender => (is => 'ro', isa => Int);
has cap      => (is => 'ro', isa => Int);

has attacks  => (is => 'rw', isa => ArrayRef, default => sub { [] });
has beats    => (is => 'rw', isa => ArrayRef, default => sub { [] });
has taken    => (is => 'rw', isa => Int, default => 0);

sub build {
    my ($class, %o) = @_;

    my ($attacker, $defender, $cap) = @o{qw(attacker defender cap)};

    die "Game::Durak::Bout: a bout wants two different seats\n"
        unless defined $attacker && defined $defender
            && $attacker =~ /\A[12]\z/ && $defender =~ /\A[12]\z/
            && $attacker != $defender;

    die "Game::Durak::Bout: a bout wants a cap of one to six, not "
        . (defined $cap ? "'$cap'" : 'undef') . "\n"
        unless defined $cap && $cap =~ /\A[1-6]\z/;

    return $class->new(
        attacker => $attacker,
        defender => $defender,
        cap      => $cap,
        attacks  => [],
        beats    => [],
        taken    => 0,
    );
}

sub size { return scalar @{ $_[0]->attacks } }

sub room { my ($self) = @_; return $self->cap - $self->size }

sub unbeaten {
    my ($self) = @_;
    my $attacks = $self->attacks;
    my $beats   = $self->beats;
    for my $i (0 .. $#$attacks) {
        return $attacks->[$i] unless defined $beats->[$i];
    }
    return undef;
}

sub all_beaten { return defined $_[0]->unbeaten ? 0 : 1 }

sub cards {
    my ($self) = @_;
    return ( @{ $self->attacks }, grep { defined } @{ $self->beats } );
}

sub ranks {
    my ($self) = @_;
    my %rank;
    $rank{ Game::Durak::Card::rank_of($_) } = 1 for $self->cards;
    return \%rank;
}

sub add_attack {
    my ($self, $card) = @_;
    die "Game::Durak::Bout: the attack is at its cap\n" if $self->room < 1;
    $self->attacks([ @{ $self->attacks }, $card ]);
    $self->beats([ @{ $self->beats }, undef ]);
    return $self;
}

sub add_beat {
    my ($self, $card) = @_;
    my $beats = [ @{ $self->beats } ];
    for my $i (0 .. $#$beats) {
        next if defined $beats->[$i];
        $beats->[$i] = $card;
        $self->beats($beats);
        return $self;
    }
    die "Game::Durak::Bout: nothing is waiting to be beaten\n";
}

1;

__END__

=head1 NAME

Game::Durak::Bout - one attack and its defence, laid out on the table

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $bout = Game::Durak::Bout->build(
        attacker => 1, defender => 2, cap => 6,
    );

    $bout->add_attack($card);
    $bout->unbeaten;              # that card, until it is answered
    $bout->add_beat($other);
    $bout->all_beaten;            # 1
    $bout->ranks;                 # { K => 1, A => 1 }, both cards

=head1 DESCRIPTION

A bout is the unit of play. One seat attacks, the other answers card by card,
and at the end the whole thing is either thrown away or picked up by the seat
that could not answer it.

The two lists are parallel: C<beats-E<gt>[$i]> is the card that answered
C<attacks-E<gt>[$i]>, or undef while it is unanswered. That is the layout the
table has, "each card played by the defender is placed face up on top of the
card it is beating, slightly offset so that the values of all cards can be
seen", and it is also what a consumer needs in order to draw it.

=head2 The cap is fixed when the bout opens

    the total number of cards played by the attackers during a bout must
    never exceed six; if the defender had fewer than six cards before the
    bout, the number of cards played by the attackers must not be more than
    the number of cards in the defender's hand.
        -- https://www.pagat.com/beating/podkidnoy_durak.html

Read that again for the word B<before>. The defender's hand shrinks by one
for every card they beat, so a cap recomputed from the hand as it stands
falls as the bout runs: a defender who started with four cards and has beaten
two would be attackable twice more instead of four times. Every deal still
finishes, every card is still accounted for, and the game is quietly a gentler
one than the rules describe.

So the cap is set once, by the constructor, from the defender's hand at that
moment, and this class offers no way to change it. C<room> is what is left.

=head2 A bout is never opened against an empty hand

C<build> dies at a cap of zero. A seat with no cards and no talon to draw from
is out of the deal, which is decided before the next bout opens, so a zero cap
means the caller has skipped that decision. It is a bug and not a refusal.

=head1 METHODS

=head2 build

    Game::Durak::Bout->build(attacker => 1, defender => 2, cap => 4);

Two different seats and a cap of one to six. Dies otherwise.

=head2 attacker, defender

The seat numbers, 1 or 2. A bout does not change hands: when the defence is
beaten off the deal opens a new bout the other way round.

=head2 cap

The most cards the attack may hold, set once.

=head2 attacks, beats

The two parallel lists. Treat them as read only and use C<add_attack> and
C<add_beat>.

=head2 taken

True once the defender has picked the bout up. The cards stay on the table
until the bout closes, because the attacker may still throw more in.

=head2 size, room

How many cards the attack holds, and how many more it may hold.

=head2 unbeaten

The first attack card with no answer, or undef. Outside the pile-on after a
take there is never more than one, because the attacker plays a card and
waits.

=head2 all_beaten

True when every attack card has been answered.

=head2 cards

Every card on the table, attacks and answers together, for the discard or for
the defender's hand.

=head2 ranks

The set of ranks on the table, B<the defender's answers included>. This is
what a new attack card has to match:

    each new attack card must be of the same rank as some card already played
    during the current bout - either an attack card or a card played by the
    defender

A set built from the attack cards alone is a subset, so nothing ever refuses a
move it should allow, no invariant breaks, and the attack is narrower than the
game's for ever.

=head2 add_attack, add_beat

Put a card on the table. Both die rather than refusing, because the rules
answer legality before either is called.

=head1 SEE ALSO

L<Game::Durak>, L<Game::Durak::Rules>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
