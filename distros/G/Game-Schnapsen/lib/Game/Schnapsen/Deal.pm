package Game::Schnapsen::Deal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Schnapsen::Card ();
use Game::Schnapsen::Deck ();
use Game::Schnapsen::Hand ();
use Game::Schnapsen::Error ();
use Game::Schnapsen::Variant ();
use Game::Schnapsen::Trick qw(winner_of value_of legal_follows);
use Game::Schnapsen::Declare qw(marriages_in exchange_card);
use Game::Schnapsen::Scoring qw(deal_result);

our $VERSION = '0.01';

has variant => (is => 'ro', isa => Str);
has seed    => (is => 'ro', isa => Str);
has number  => (is => 'ro', isa => Int);
has dealer  => (is => 'ro', isa => Str);
has trump   => (is => 'ro', isa => Str);

has hands   => (is => 'rw', isa => HashRef);
has talon   => (is => 'rw', isa => ArrayRef);
has turn_up => (is => 'rw', isa => Int);
has drawn   => (is => 'rw', isa => Int);

has closed      => (is => 'rw', isa => Int);
has closed_by   => (is => 'rw', isa => Str);
has close_state => (is => 'rw', isa => HashRef);

has tricks  => (is => 'rw', isa => ArrayRef);
has taken   => (is => 'rw', isa => HashRef);
has melds   => (is => 'rw', isa => ArrayRef);

has turn      => (is => 'rw', isa => Str);
has leader    => (is => 'rw', isa => Str);
has lead      => (is => 'rw', isa => Int);
has must_lead => (is => 'rw', isa => ArrayRef);

has result  => (is => 'rw', isa => HashRef);
has history => (is => 'rw', isa => ArrayRef);

sub _v { return $_[0]->variant }

sub other { return $_[0] eq 'p1' ? 'p2' : 'p1' }

sub build {
    my ($class, %o) = @_;

    my $bad = Game::Schnapsen::Variant::check_variant($o{variant});
    return $bad if $bad;

    my $seed = $o{seed};
    return Game::Schnapsen::Error->new_code('no_seed')
        unless defined $seed && length $seed == 32;

    my $number = defined $o{number} ? $o{number} : 1;
    return Game::Schnapsen::Error->new_code('bad_deal')
        unless $number =~ /\A[1-9][0-9]*\z/;

    my $dealer = $o{dealer} || 'p1';
    my $pone   = other($dealer);

    my $deal = Game::Schnapsen::Deck::deal_for($seed, $number, $o{variant});

    return $class->new(
        variant => $o{variant},
        seed    => $seed,
        number  => $number,
        dealer  => $dealer,
        trump   => Game::Schnapsen::Card::suit_of($deal->{turn_up}),
        hands   => {
            $pone   => Game::Schnapsen::Hand->new(cards => [ @{ $deal->{non_dealer} } ]),
            $dealer => Game::Schnapsen::Hand->new(cards => [ @{ $deal->{dealer} } ]),
        },
        talon   => [ @{ $deal->{talon} } ],
        turn_up => $deal->{turn_up},
        drawn   => 1,
        closed      => 0,
        closed_by   => undef,
        close_state => undef,
        tricks  => [],
        taken   => { p1 => 0, p2 => 0 },
        melds   => [],
        turn      => $pone,
        leader    => $pone,
        lead      => undef,
        must_lead => undef,
        result  => undef,
        history => [],
    );
}

sub hand_of  { return $_[0]->hands->{ $_[1] } }
sub points_of { return $_[0]->taken->{ $_[1] } || 0 }

sub tricks_won {
    my ($self, $seat) = @_;
    return scalar grep { $_->{winner} eq $seat } @{ $self->tricks };
}

sub talon_left {
    my ($self) = @_;
    return scalar(@{ $self->talon }) + (defined $self->turn_up ? 1 : 0);
}

sub draw_left {
    my ($self) = @_;
    return 0 if $self->closed;
    return $self->talon_left;
}

sub phase { return $_[0]->draw_left ? 1 : 2 }

sub cards_out {
    my ($self) = @_;
    return $self->hand_of('p1')->count == 0 && $self->hand_of('p2')->count == 0 ? 1 : 0;
}

sub over {
    my ($self) = @_;
    return 1 if $self->result;
    return $self->cards_out;
}

sub last_trick {
    my ($self) = @_;
    my $t = $self->tricks;
    return @$t ? $t->[-1] : undef;
}

sub pending_draw { return $_[0]->drawn ? 0 : 1 }

sub can_exchange {
    my ($self, $seat) = @_;
    return undef if $self->closed || $self->pending_draw;
    return undef unless $self->draw_left && defined $self->turn_up;
    return undef if Game::Schnapsen::Variant::exchange_needs_trick($self->_v)
                 && !$self->tricks_won($seat);
    return exchange_card($self->hand_of($seat)->cards, $self->trump,
                         Game::Schnapsen::Variant::exchange_rank($self->_v));
}

sub can_close {
    my ($self, $seat) = @_;
    return 0 if $self->closed || !$self->draw_left;
    return 0 if $self->pending_draw
             && !Game::Schnapsen::Variant::close_before_draw($self->_v);
    return 1;
}

sub can_claim {
    my ($self, $seat) = @_;
    return 0 if $self->over || defined $self->lead;
    return 0 unless ($self->turn // '') eq $seat;
    return 1 if @{ $self->tricks };
    return 1 if grep { $_->{seat} eq $seat } @{ $self->melds };
    return 0;
}

sub can_marry {
    my ($self, $seat) = @_;
    return [] if $self->must_lead || $self->pending_draw;
    return [] unless Game::Schnapsen::Variant::marriage_after_close($self->_v)
                  || $self->phase == 1;
    return marriages_in($self->hand_of($seat)->cards, $self->trump);
}

sub legal {
    my ($self, $seat) = @_;
    return [] if $self->over;
    return [] unless defined $seat && ($self->turn // '') eq $seat;

    my $hand = $self->hand_of($seat);

    if (defined $self->lead) {
        my $can = legal_follows($hand->cards, $self->lead, $self->trump, $self->phase);
        return [ map { { kind => 'follow', card => $_ } } @$can ];
    }

    if ($self->pending_draw) {
        my @out;
        push @out, { kind => 'claim' } if $self->can_claim($seat);
        push @out, { kind => 'close' } if $self->can_close($seat);
        push @out, { kind => 'draw' };
        return \@out;
    }

    my @out;
    push @out, { kind => 'claim' } if $self->can_claim($seat);
    push @out, { kind => 'exchange' } if $self->can_exchange($seat);
    push @out, { kind => 'close' } if $self->can_close($seat);
    push @out, { kind => 'marriage', suit => $_->{suit}, value => $_->{value} }
        for @{ $self->can_marry($seat) };

    my $leads = $self->must_lead || $hand->cards;
    push @out, { kind => 'lead', card => $_ } for @$leads;
    return \@out;
}

my %HANDLER = (
    lead     => '_lead',
    follow   => '_follow',
    draw     => '_draw_move',
    marriage => '_marriage',
    exchange => '_exchange',
    close    => '_close',
    claim    => '_claim',
);

sub apply {
    my ($self, $seat, $move) = @_;
    return Game::Schnapsen::Error->new_code('deal_over') if $self->over;
    return Game::Schnapsen::Error->new_code('not_your_turn')
        unless defined $seat && ($self->turn // '') eq $seat;

    my $kind = ref $move eq 'HASH' ? ($move->{kind} // '') : '';

    my @allowed = defined $self->lead ? ('follow')
                : $self->pending_draw ? ('draw', 'close', 'claim')
                : ('lead', 'marriage', 'exchange', 'close', 'claim');
    return Game::Schnapsen::Error->new_code('not_legal')
        unless grep { $_ eq $kind } @allowed;

    my $handler = $HANDLER{$kind};
    my @out = $self->$handler($seat, $move);

    return $out[0] if @out == 1 && ref $out[0] eq 'Game::Schnapsen::Error';
    $self->history([ @{ $self->history || [] }, @out ]);
    return @out;
}

sub _held {
    my ($self, $seat, $move) = @_;
    my $card = $move->{card};
    return Game::Schnapsen::Error->new_code('not_held')
        unless defined $card && $card =~ /\A[1-9][0-9]*\z/
            && $self->hand_of($seat)->has_card($card);
    return $card;
}

sub _lead {
    my ($self, $seat, $move) = @_;
    my $card = $self->_held($seat, $move);
    return $card if ref $card;

    if (my $must = $self->must_lead) {
        return Game::Schnapsen::Error->new_code('must_lead')
            unless grep { $_ == $card } @$must;
    }

    $self->hand_of($seat)->remove($card);
    $self->must_lead(undef);
    $self->leader($seat);
    $self->lead($card);
    $self->turn(other($seat));

    return ({ kind => 'lead', seat => $seat, card => $card });
}

sub _count_melds {
    my ($self, $seat) = @_;
    my $add = 0;
    for my $m (@{ $self->melds }) {
        next if $m->{counted} || $m->{seat} ne $seat;
        $m->{counted} = 1;
        $add += $m->{value};
    }
    return 0 unless $add;
    my $taken = { %{ $self->taken } };
    $taken->{$seat} += $add;
    $self->taken($taken);
    return $add;
}

sub _marriage {
    my ($self, $seat, $move) = @_;
    my $suit = ref $move eq 'HASH' ? $move->{suit} : undef;
    return Game::Schnapsen::Error->new_code('no_marriage') unless defined $suit;

    my ($m) = grep { $_->{suit} eq $suit } @{ $self->can_marry($seat) };
    return Game::Schnapsen::Error->new_code('no_marriage') unless $m;

    $self->melds([ @{ $self->melds },
                   { seat => $seat, suit => $suit, value => $m->{value}, counted => 0 } ]);
    $self->_count_melds($seat) if $self->tricks_won($seat);
    $self->must_lead([ $m->{king}, $m->{queen} ]);

    return ({ kind => 'marriage', seat => $seat, suit => $suit, value => $m->{value} });
}

sub _exchange {
    my ($self, $seat, $move) = @_;
    my $card = $self->can_exchange($seat);
    return Game::Schnapsen::Error->new_code('no_exchange') unless defined $card;
    $self->_swap_trump($seat, $card);
    return ({ kind => 'exchange', seat => $seat });
}

sub _swap_trump {
    my ($self, $seat, $card) = @_;
    my $up = $self->turn_up;
    $self->hand_of($seat)->remove($card);
    $self->hand_of($seat)->add($up);
    $self->turn_up($card);
    return;
}

sub _close {
    my ($self, $seat, $move) = @_;
    return Game::Schnapsen::Error->new_code('cannot_close') unless $self->can_close($seat);

    $self->close_state({
        by => $seat,
        map { ($_ => { tricks => $self->tricks_won($_), points => $self->points_of($_) }) }
            qw(p1 p2),
    });
    $self->closed(1);
    $self->closed_by($seat);
    $self->drawn(1);

    my @out = ({ kind => 'close', seat => $seat });

    if (Game::Schnapsen::Variant::exchange_on_close($self->_v) && defined $self->turn_up) {
        my $them = other($seat);
        my $card = exchange_card($self->hand_of($them)->cards, $self->trump,
                                 Game::Schnapsen::Variant::exchange_rank($self->_v));
        if (defined $card) {
            $self->_swap_trump($them, $card);
            push @out, { kind => 'exchange', seat => $them };
        }
    }
    return @out;
}

sub _finish {
    my ($self, $how, $by) = @_;
    my $r = deal_result(
        variant     => $self->variant,
        how         => $how,
        by          => $by,
        points      => { p1 => $self->points_of('p1'), p2 => $self->points_of('p2') },
        tricks      => { p1 => $self->tricks_won('p1'), p2 => $self->tricks_won('p2') },
        closed_by   => $self->closed_by,
        close_state => $self->close_state,
        last_trick  => ($self->last_trick ? $self->last_trick->{winner} : undef),
    );
    $self->result($r);
    return { %$r, kind => 'deal_end' };
}

sub _claim {
    my ($self, $seat, $move) = @_;
    return Game::Schnapsen::Error->new_code('cannot_claim') unless $self->can_claim($seat);
    return ({ kind => 'claim', seat => $seat }, $self->_finish('claim', $seat));
}

sub _draw_move {
    my ($self, $seat, $move) = @_;
    $self->_draw_now;
    return ({ kind => 'draw', seat => $seat });
}

sub _follow {
    my ($self, $seat, $move) = @_;
    my $card = $self->_held($seat, $move);
    return $card if ref $card;

    my $can = legal_follows($self->hand_of($seat)->cards,
                            $self->lead, $self->trump, $self->phase);
    return Game::Schnapsen::Error->new_code('must_follow')
        unless grep { $_ == $card } @$can;

    $self->hand_of($seat)->remove($card);

    my $lead   = $self->lead;
    my $leader = $self->leader;
    my $best   = winner_of($lead, $card, $self->trump);
    my $winner = $best == $lead ? $leader : $seat;

    my $taken = { %{ $self->taken } };
    $taken->{$winner} += value_of($lead, $card);
    $self->taken($taken);

    $self->tricks([ @{ $self->tricks },
                    { leader => $leader, lead => $lead, follow => $card,
                      winner => $winner } ]);

    $self->lead(undef);
    $self->leader($winner);
    $self->turn($winner);

    $self->_count_melds($winner);

    $self->drawn(1);
    if ($self->draw_left) {
        if (Game::Schnapsen::Variant::close_before_draw($self->_v)) { $self->drawn(0) }
        else { $self->_draw_now }
    }

    my @out = ({ kind => 'follow', seat => $seat, card => $card },
               { kind => 'trick', winner => $winner });
    push @out, $self->_finish('exhausted') if $self->cards_out;
    return @out;
}

sub _draw_now {
    my ($self) = @_;
    $self->drawn(1);
    return unless $self->draw_left;
    my $winner = $self->leader;

    for my $seat ($winner, other($winner)) {
        my $card;
        if (@{ $self->talon }) {
            my @rest = @{ $self->talon };
            $card = shift @rest;
            $self->talon(\@rest);
        }
        elsif (defined $self->turn_up) {
            $card = $self->turn_up;
            $self->turn_up(undef);
        }
        last unless defined $card;
        $self->hand_of($seat)->add($card);
    }
    return;
}

1;

__END__

=head1 NAME

Game::Schnapsen::Deal - one deal, its talon, and its two phases

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $deal = Game::Schnapsen::Deal->build(
        variant => 'schnapsen',
        seed    => $thirty_two_bytes,
        number  => 1,
        dealer  => 'p1',
    );

    $deal->trump;                 # the suit of the turn-up
    $deal->phase;                 # 1 while the talon is open, 2 after
    $deal->legal("p2");           # [ { kind => "lead", card => 7 }, ... ]
    $deal->apply('p2', { kind => 'lead', card => 7 });

=head1 DESCRIPTION

A deal of Schnapsen or of Sixty-Six. The non-dealer leads to the first trick.

=head2 The state of this module

A whole deal is implemented: leading, following, winning a trick, drawing,
marriages, the trump exchange, closing the talon, claiming, and the four ways a
deal can end. What is not here is the match around it, which is
L<Game::Schnapsen>'s: deal rotation, the running game-point score, and who wins
the whole thing.

=head2 A declaration does not consume the turn

A marriage, a trump exchange and a close all belong to the player whose turn it
is to lead, they happen before that lead, and afterwards that player is still on
lead. So C<turn> does not change, and a lead follows.

Riding a declaration on the lead itself, as C<< { kind => 'lead', card => $id,
marriage => 1 } >>, cannot express the game: both rulesets let a player declare a
marriage and go out immediately on the strength of the twenty or forty, without
leading at all.

The cost is a round trip, and only in the turns where a declaration happens.

=head2 Why the draw is not always automatic

In Sixty-Six the talon may be closed either before or after drawing, and in
Schnapsen only after. So Sixty-Six has a moment that Schnapsen does not: the
trick is over, the winner is on lead, and the draw has not happened yet. At that
moment C<legal> offers exactly C<close> and C<draw>, and drawing is how a player
declines to close.

Schnapsen has no such moment, so it draws by itself and C<draw> is never a move
there. C<pending_draw> says which state a deal is in.

This costs Sixty-Six one extra turn per trick, which is worth knowing before
measuring how long a match takes.

It would be cheaper to draw immediately in both games and let the player close
afterwards, and that is a different game: the choice to close before drawing is
made B<without having seen the card you would have drawn>, and offering it after
the draw hands the closer information the rules do not give them.

=head2 A marriage does not count until its owner takes a trick

Declaring is recorded in C<melds> as pending. The twenty or forty is added to
C<taken> at the moment that player first takes a trick, and a player who declares
and never takes one scores nothing for it. Declaring when a trick has already
been taken counts at once.

This is the rule most often got wrong, and getting it wrong gives a deal that
looks right all the way through and is simply worth more than it should be.

=head2 The close-time exchange is applied rather than offered

In Sixty-Six, closing the talon lets the B<opponent> exchange the trump nine at
that moment, even having won no trick. That is an action belonging to the player
who is not on lead, and making it a move would need the turn to change hands in
the middle of one.

It is applied automatically instead. The nine is worth no card points and the
turn-up is worth between two and eleven, so taking the exchange is never worse
and declining is never right, which makes it not a decision worth a turn. It
still produces its own C<exchange> outcome, so a log and a replay show it
happening.

This is a deliberate deviation from the letter of the source, which offers it,
and it is recorded here rather than left to be discovered.

=head2 The two phases

C<phase> is 1 while anything remains to be drawn and 2 once nothing does,
whether because the talon ran out or because somebody closed it. It is derived
rather than stored, so it cannot disagree with the talon.

The rules of each phase are L<Game::Schnapsen::Trick>'s business and are the
same in both games.

=head2 A draw is not a move

Both players draw after every trick, the winner first, and there is no choice in
it at any point. So drawing is a consequence of a trick rather than a turn, it
produces no event of its own, and a consumer's move log never records which card
was drawn.

That is not a saving of bytes. The card drawn is the next off an order the seed
already fixed, so it is derivable from the seed and the number of tricks played,
and a payload that never held it cannot leak it however a log is filtered later.
A consumer keeping hands secret gets that for nothing.

=head2 The winner draws first

With an odd number of face-down cards left this decides who receives the turn-up,
which is the one card in the talon both players have seen. Both rulesets are
explicit about the order, and getting it backwards gives a legal, replayable,
entirely plausible game that is simply not the one in the book.

=head2 talon_left and draw_left are different numbers

C<talon_left> counts the cards physically there. C<draw_left> is how many may
still be drawn, which is zero once the talon is closed even though the cards
remain. The two are equal until somebody closes.

They are kept apart because a closed talon and an empty one play identically and
score differently, so a single number would be right about the play and wrong
about the result.

=head1 METHODS

=head2 build

    Game::Schnapsen::Deal->build(variant => ..., seed => ..., number => ..., dealer => ...);

A new deal, or a L<Game::Schnapsen::Error> for a variant this engine does not
play, a seed that is not 32 bytes, or a deal number below one.

=head2 variant, seed, number, dealer, trump

What the deal was built with, and the trump suit the turn-up set.

=head2 hands, hand_of

The two L<Game::Schnapsen::Hand> objects, and one of them by seat.

=head2 talon, turn_up

The face-down cards in draw order, and the face-up trump card, which is undef
once it has been drawn.

=head2 talon_left, draw_left, closed, closed_by, close_state, drawn, pending_draw

How many cards are there, how many may be drawn, whether the talon has been
closed and by whom, and where both players stood at the instant it was closed.

C<close_state> is taken on every close in both games, as
C<< { by, p1 => { tricks, points }, p2 => { ... } } >>. Schnapsen scores the
closer's opponent as they stood at that moment and Sixty-Six counts their whole
deal, so only one of the two games reads it; taking it unconditionally costs
nothing and keeps the Schnapsen path from being a special case that exists only
sometimes.

C<drawn> and C<pending_draw> say whether the draw for the last trick has
happened.

=head2 melds, must_lead

The marriages declared, as C<< { seat, suit, value, counted } >>, and the two
cards a player who has just declared one is now obliged to lead from.

=head2 can_exchange, can_close, can_marry, can_claim

What the seat on lead may declare: the id of the exchange card or undef, two
booleans, and the marriages available. C<legal> is built from these, and they are
public because a consumer wants to explain why an option is absent.

C<can_claim> is about B<timing and nothing else>: "A claim may be made just after
winning a trick or just after declaring a marriage, but not at any other time."
It does B<not> check whether the player actually holds 66, and it must not. A
claim offered only when it would succeed makes the penalty for a false one
unreachable, and a rule that cannot be broken is a rule that is not implemented.

=head2 phase

1 or 2.

=head2 tricks, last_trick, tricks_won

Every trick as C<{ leader, lead, follow, winner }>, the most recent, and how
many a seat has taken.

=head2 taken, points_of

The card points each seat has taken. Both players count openly in this family,
so these are public: it is the points still in a hand that are secret.

=head2 turn, leader, lead

Whose move it is, who led the current trick, and the card they led, which is
undef between tricks.

=head2 cards_out, over, result

Whether the hands are empty, whether the deal has finished, and how it finished.
C<result> is L<Game::Schnapsen::Scoring>'s verdict, set the moment the deal ends,
and undef before then.

A deal ends in one of four ways: somebody claims correctly, somebody claims
wrongly, a closer runs out of cards without going out, or the cards run out with
no close and no claim. The last of those is the one the two games disagree about
most.

Note that a deal is never ended by arithmetic. Reaching 66 does nothing at all
until a player says so, which is what makes a false claim possible and is
required by both sources.

=head2 history

Every outcome C<apply> has returned, in order. The deal's own record of itself,
which is not the same thing as a consumer's move log and is not a
serialisation: rebuilding from the seed and replaying the moves is.

=head2 other

    Game::Schnapsen::Deal::other('p1');    # 'p2'

The other seat. A function rather than a method, because it is about the two
seats and not about any one deal.

=head2 legal

    $deal->legal($seat);

What that seat may do, as a list of C<{ kind, card }>. Empty for the seat that
is not to move and for a finished deal.

=head2 apply

    $deal->apply($seat, { kind => 'lead', card => $id });

Returns the outcomes as a list of hashrefs, or a single
L<Game::Schnapsen::Error>. Following a trick returns both the C<follow> and the
C<trick> it completed.

=head1 SEE ALSO

L<Game::Schnapsen::Trick>, L<Game::Schnapsen::Deck>, L<Game::Schnapsen::Hand>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
