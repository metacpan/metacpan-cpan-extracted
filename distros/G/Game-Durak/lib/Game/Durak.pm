package Game::Durak;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Durak::Card ();
use Game::Durak::Deck qw(HAND_SIZE);
use Game::Durak::Bout ();
use Game::Durak::Error ();
use Game::Durak::Rules qw(cap_for legal_attacks legal_beats forced closes);
use Game::Durak::Result qw(out_seats result_for resign_for);

our $VERSION = '0.01';

has seed       => (is => 'ro', isa => Str);
has number     => (is => 'ro', isa => Int);
has trump      => (is => 'ro', isa => Str);
has trump_card => (is => 'rw', isa => Int);

has hands     => (is => 'rw', isa => HashRef);
has talon     => (is => 'rw', isa => ArrayRef);
has discard   => (is => 'rw', isa => Int, default => 0);
has bout      => (is => 'rw');
has six_owner => (is => 'rw');
has over      => (is => 'rw', isa => Int, default => 0);
has result    => (is => 'rw');
has history   => (is => 'rw', isa => ArrayRef, default => sub { [] });

sub build {
    my ($class, %o) = @_;

    my $seed = $o{seed};
    return Game::Durak::Error->new_code('no_seed')
        unless defined $seed && length $seed == 32;

    my $number = defined $o{number} ? $o{number} : 1;
    return Game::Durak::Error->new_code('bad_deal')
        unless $number =~ /\A[1-9][0-9]*\z/;

    my $seats = defined $o{seats} ? $o{seats} : Game::Durak::Deck::SEATS;
    return Game::Durak::Error->new_code('bad_seats')
        unless $seats =~ /\A[0-9]+\z/ && $seats == Game::Durak::Deck::SEATS;

    my $deal = Game::Durak::Deck::deal_for($seed, $number, $seats);

    my $six = Game::Durak::Card::six_of($deal->{trump});
    my ($owner) = grep {
        scalar grep { $_ == $six } @{ $deal->{hands}{$_} }
    } 1 .. $seats;

    my $self = $class->new(
        seed       => $seed,
        number     => $number,
        trump      => $deal->{trump},
        trump_card => $deal->{trump_card},
        hands      => { map { $_ => [ @{ $deal->{hands}{$_} } ] } 1 .. $seats },
        talon      => [ @{ $deal->{talon} } ],
        discard    => 0,
        bout       => undef,
        six_owner  => $owner,
        over       => 0,
        result     => undef,
        history    => [],
    );

    $self->_open_bout($deal->{first});
    return $self;
}

sub _other { return 3 - $_[0] }

sub hand_of { return $_[0]->hands->{ $_[1] } }

sub count_of { return scalar @{ $_[0]->hands->{ $_[1] } } }

sub talon_left { return scalar @{ $_[0]->talon } }

sub seats { return ( 1, 2 ) }

sub six_of_trumps { return Game::Durak::Card::six_of($_[0]->trump) }

sub turn_up_left {
    my ($self) = @_;
    my $up = $self->trump_card;
    return scalar(grep { $_ == $up } @{ $self->talon }) ? 1 : 0;
}

sub can_swap {
    my ($self, $seat) = @_;
    return 0 if $self->over;
    my $owner = $self->six_owner;
    return 0 unless defined $owner && defined $seat && $owner == $seat;
    my $six = $self->six_of_trumps;
    return 0 unless grep { $_ == $six } @{ $self->hand_of($seat) };
    return $self->turn_up_left;
}

sub phase {
    my ($self) = @_;
    return 'over' if $self->over;
    my $bout = $self->bout;
    return 'over' unless $bout;
    return 'pile_on' if $bout->taken;
    return 'defend' if defined $bout->unbeaten;
    return 'attack';
}

sub turn {
    my ($self) = @_;
    my $phase = $self->phase;
    return undef if $phase eq 'over';
    my $bout = $self->bout;
    return $phase eq 'defend' ? $bout->defender : $bout->attacker;
}

sub legal {
    my ($self, $seat) = @_;
    return [] if $self->over;
    return [] unless defined $seat && $seat =~ /\A[12]\z/;
    my $turn = $self->turn;
    return [] unless defined $turn && $turn == $seat;

    my $bout = $self->bout;
    my $hand = $self->hand_of($seat);
    my @out;

    my $swap = $self->can_swap($seat);

    if ($self->phase eq 'defend') {
        my $beats = legal_beats($hand, $bout, $self->trump);
        push @out, map { { kind => 'beat', card => $_ } } @$beats;
        push @out, { kind => 'take' } if @$beats || $swap;
        push @out, { kind => 'swap' } if $swap;
        return \@out;
    }

    my $attacks = legal_attacks($hand, $bout);
    push @out, map { { kind => 'attack', card => $_ } } @$attacks;
    push @out, { kind => 'done' } if $bout->size && (@$attacks || $swap);
    push @out, { kind => 'swap' } if $swap;
    return \@out;
}

sub view {
    my ($self, $seat) = @_;
    die "Game::Durak: a view is for a seat\n"
        unless defined $seat && $seat =~ /\A[12]\z/;

    my $bout = $self->bout;

    return {
        seat       => $seat,
        ply        => scalar @{ $self->history },
        phase      => $self->phase,
        turn       => $self->turn,
        trump      => $self->trump,
        trump_card => $self->turn_up_left ? $self->trump_card : undef,
        talon      => $self->talon_left,
        discard    => $self->discard,
        hand       => [ @{ $self->hand_of($seat) } ],
        counts     => { map { $_ => $self->count_of($_) } $self->seats },
        swap       => $self->can_swap($seat),
        legal      => $self->legal($seat),
        over       => $self->over,
        result     => $self->result,
        bout       => $bout ? {
            attacker => $bout->attacker,
            defender => $bout->defender,
            cap      => $bout->cap,
            size     => $bout->size,
            taken    => $bout->taken,
            unbeaten => $bout->unbeaten,
            pairs    => [ map {
                { attack => $bout->attacks->[$_], beat => $bout->beats->[$_] }
            } 0 .. $bout->size - 1 ],
        } : undef,
    };
}

my %HANDLER = (
    attack => '_attack',
    beat   => '_beat',
    take   => '_take',
    done   => '_done',
    swap   => '_swap',
);

my %STAGE = (
    attack => { attack => 1, pile_on => 1 },
    beat   => { defend  => 1 },
    take   => { defend  => 1 },
    done   => { attack  => 1, pile_on => 1 },
    swap   => { attack  => 1, pile_on => 1, defend => 1 },
    resign => { attack  => 1, pile_on => 1, defend => 1 },
);

sub apply {
    my ($self, $seat, $move) = @_;

    return Game::Durak::Error->new_code('game_over') if $self->over;
    return Game::Durak::Error->new_code('not_your_turn')
        unless defined $seat && $seat =~ /\A[12]\z/;

    my $kind = ref $move eq 'HASH' && defined $move->{kind} ? $move->{kind} : '';
    return Game::Durak::Error->new_code('not_legal') unless $STAGE{$kind};

    my @out;
    if ($kind eq 'resign') {
        @out = $self->_resign($seat);
    }
    else {
        my $turn = $self->turn;
        return Game::Durak::Error->new_code('not_your_turn')
            unless defined $turn && $turn == $seat;
        return Game::Durak::Error->new_code('wrong_phase')
            unless $STAGE{$kind}{ $self->phase };

        my $handler = $HANDLER{$kind};
        @out = $self->$handler($seat, $move);
        return $out[0] if @out == 1 && ref $out[0] eq 'Game::Durak::Error';

        push @out, $self->_advance;
    }

    $self->history([ @{ $self->history }, @out ]);
    return @out;
}

sub is_move { return $STAGE{ defined $_[1] ? $_[1] : '' } ? 1 : 0 }

sub moves_of {
    my ($class, $events) = @_;
    return [ grep { $class->is_move($_->{kind}) && defined $_->{seat} } @$events ];
}

sub replay {
    my ($class, %o) = @_;

    my $moves = delete $o{moves};
    $moves = [] unless defined $moves;

    my $game = $class->build(%o);
    return $game if ref $game eq 'Game::Durak::Error';

    my @events;
    for my $move (@$moves) {
        my @out = $game->apply($move->{seat}, $move);
        return $out[0] if ref $out[0] eq 'Game::Durak::Error';
        push @events, @out;
    }

    return { game => $game, events => \@events };
}

sub _held {
    my ($self, $seat, $move) = @_;
    my $card = ref $move eq 'HASH' ? $move->{card} : undef;
    return Game::Durak::Error->new_code('card_not_held')
        unless defined $card && $card =~ /\A[1-9][0-9]*\z/
            && grep { $_ == $card } @{ $self->hand_of($seat) };
    return $card;
}

sub _attack {
    my ($self, $seat, $move) = @_;
    my $card = $self->_held($seat, $move);
    return $card if ref $card;

    my $bout = $self->bout;
    return Game::Durak::Error->new_code('bout_full') if $bout->room < 1;

    if ($bout->size) {
        return Game::Durak::Error->new_code('rank_not_in_bout')
            unless $bout->ranks->{ Game::Durak::Card::rank_of($card) };
    }

    $self->_remove($seat, $card);
    $bout->add_attack($card);
    return ({ kind => 'attack', seat => $seat, card => $card });
}

sub _beat {
    my ($self, $seat, $move) = @_;
    my $card = $self->_held($seat, $move);
    return $card if ref $card;

    my $bout = $self->bout;
    my $att  = $bout->unbeaten;
    die "Game::Durak: the defending stage with nothing to beat\n"
        unless defined $att;

    return Game::Durak::Error->new_code('beats_nothing')
        unless Game::Durak::Card::beats($card, $att, $self->trump);

    $self->_remove($seat, $card);
    $bout->add_beat($card);
    return ({ kind => 'beat', seat => $seat, card => $card });
}

sub _take {
    my ($self, $seat) = @_;
    $self->bout->taken(1);
    return ({ kind => 'take', seat => $seat });
}

sub _done {
    my ($self, $seat) = @_;
    my $bout = $self->bout;
    return Game::Durak::Error->new_code('must_attack') unless $bout->size;
    return ({ kind => 'done', seat => $seat },
            $self->_close_bout($bout->taken ? 'taken' : 'done'));
}

sub _swap {
    my ($self, $seat) = @_;

    my $six   = $self->six_of_trumps;
    my $owner = $self->six_owner;

    return Game::Durak::Error->new_code('not_the_six')
        unless defined $owner && $owner == $seat
            && grep { $_ == $six } @{ $self->hand_of($seat) };

    return Game::Durak::Error->new_code('talon_shut') unless $self->turn_up_left;

    my $up    = $self->trump_card;
    my $talon = [ @{ $self->talon } ];
    die "Game::Durak: the turn-up is not the last card of the talon\n"
        unless @$talon && $talon->[-1] == $up;

    $talon->[-1] = $six;
    $self->talon($talon);

    $self->_remove($seat, $six);
    $self->_give($seat, $up);
    $self->trump_card($six);
    $self->six_owner(undef);

    return ({ kind => 'swap', seat => $seat });
}

sub _resign {
    my ($self, $seat) = @_;
    my $result = resign_for($seat, [ $self->seats ]);
    $self->_finish($result);
    return ({ kind => 'resign', seat => $seat },
            { kind => 'game_end', %$result });
}

sub _advance {
    my ($self) = @_;
    my @out;

    while (1) {
        last if $self->over;
        my $bout = $self->bout;
        last unless $bout;

        if ($bout->taken) {
            last unless $bout->room < 1 || $self->_forced($bout->attacker);
            push @out, $self->_close_bout('taken');
            next;
        }

        my $how = closes($bout, $self->count_of($bout->defender));
        if ($how) {
            push @out, $self->_close_bout($how);
            next;
        }

        my $turn = $self->turn;
        last unless $self->_forced($turn);

        if ($self->phase eq 'defend') {
            $bout->taken(1);
            next;
        }

        last unless $bout->size;
        push @out, $self->_close_bout('exhausted');
    }

    return @out;
}

sub _forced {
    my ($self, $seat) = @_;
    return forced($self->hand_of($seat), $self->bout, $self->trump,
                  $self->phase, $self->can_swap($seat));
}

sub _close_bout {
    my ($self, $how) = @_;

    my $bout     = $self->bout;
    my @cards    = $bout->cards;
    my $taken    = $bout->taken ? 1 : 0;
    my $attacker = $bout->attacker;
    my $defender = $bout->defender;
    my $next     = $taken ? $attacker : $defender;

    if ($taken) {
        my $hands = { %{ $self->hands } };
        $hands->{$defender} =
            [ sort { $a <=> $b } @{ $hands->{$defender} }, @cards ];
        $self->hands($hands);

        my $six   = $self->six_of_trumps;
        my $owner = $self->six_owner;
        $self->six_owner(undef)
            if defined $owner && $owner != $defender
            && grep { $_ == $six } @cards;
    }
    else {
        $self->discard($self->discard + scalar @cards);
    }

    my $event = {
        kind          => 'bout_end',
        taken         => $taken,
        how           => $how,
        cards         => scalar @cards,
        discard       => $self->discard,
        next_attacker => $next,
    };

    $self->bout(undef);
    return ($event, $self->_refill($attacker, $defender),
            $self->_after_bout($next));
}

sub _refill {
    my ($self, $first, $second) = @_;
    my %drawn = (1 => 0, 2 => 0);
    $drawn{$_} = $self->_draw_to($_) for $first, $second;
    return {
        kind  => 'refill',
        drawn => \%drawn,
        talon => $self->talon_left,
    };
}

sub _draw_to {
    my ($self, $seat) = @_;

    my $talon = [ @{ $self->talon } ];
    my $six   = $self->six_of_trumps;
    my $drawn = 0;

    while (@$talon && $self->count_of($seat) < HAND_SIZE) {
        my $card = shift @$talon;
        $self->_give($seat, $card);
        $self->six_owner($seat) if $card == $six;
        $drawn++;
    }

    $self->talon($talon);
    return $drawn;
}

sub _after_bout {
    my ($self, $next) = @_;

    my $counts = { map { $_ => $self->count_of($_) } $self->seats };
    my $result = result_for($counts, $self->talon_left);

    unless ($result) {
        $self->_open_bout($next);
        return ();
    }

    my @out = map { { kind => 'out', seat => $_ } }
              out_seats($counts, $self->talon_left);

    $self->_finish($result);
    return (@out, { kind => 'game_end', %$result });
}

sub _finish {
    my ($self, $result) = @_;
    die "Game::Durak: the deal has a result already\n" if $self->result;
    $self->result($result);
    $self->over(1);
    return;
}

sub _open_bout {
    my ($self, $attacker) = @_;
    my $defender = _other($attacker);
    $self->bout(Game::Durak::Bout->build(
        attacker => $attacker,
        defender => $defender,
        cap      => cap_for($self->count_of($defender)),
    ));
    return;
}

sub _give {
    my ($self, $seat, @cards) = @_;
    my $hands = { %{ $self->hands } };
    $hands->{$seat} = [ sort { $a <=> $b } @{ $hands->{$seat} }, @cards ];
    $self->hands($hands);
    return;
}

sub _remove {
    my ($self, $seat, $card) = @_;
    my $hands = { %{ $self->hands } };
    my $gone  = 0;
    my @left;
    for my $id (@{ $hands->{$seat} }) {
        if (!$gone && $id == $card) { $gone = 1; next }
        push @left, $id;
    }
    $hands->{$seat} = \@left;
    $self->hands($hands);
    return $gone;
}

1;

__END__

=head1 NAME

Game::Durak - Podkidnoy Durak, the Russian beating game

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Durak;

    my $game = Game::Durak->build(seed => $thirty_two_bytes);

    $game->trump;                 # 'H'
    $game->turn;                  # 1 or 2
    $game->phase;                 # 'attack', 'defend', 'pile_on' or 'over'
    $game->legal($game->turn);    # [ { kind => 'attack', card => 14 }, ... ]

    my @events = $game->apply(1, { kind => 'attack', card => 14 });
    if (ref $events[0] eq 'Game::Durak::Error') { ... }

=head1 DESCRIPTION

Two seats, a thirty-six card pack and a trump suit, played in bouts. One seat
attacks with a card, the other beats it or picks it up, and the attacker may
keep throwing in cards whose rank is already on the table. A bout that is
beaten off goes to the discard and the defender attacks next; a bout that is
taken goes into the defender's hand and the attacker attacks again.

Between bouts each seat draws back up to six from the talon, the attacker
first, and the holder of the trump six may exchange it for the turned up
trump while that card is still in the talon.

The game has no winner, only a loser: the seat left holding cards when the
talon is empty and the other has run out is the durak, the fool. If the last
bout empties both hands the deal is drawn.

It is the engine behind the Durak at L<https://peer2peergames.com>.

=head2 The deal ends at a bout end, after the refill, and nowhere else

A seat is out when it has no cards and there is no talon to draw from, and
both of those are only true at the moment a bout closes and the drawing is
done. So a defender that has just picked a bout up is never out, it is
holding the bout; an attacker that plays its last card is not out until the
defender has answered; and a defender that beats the last attack with its
last card is out on that card.

L<Game::Durak::Result> is the whole of it, over two card counts and the size
of the talon.

=head2 A seat is 1 or 2

Not C<p1> and C<p2>, which is what the sibling engines in this family use,
because a seat here indexes the deal that L<Game::Durak::Deck> produces and an
engine that converts between two spellings of the same thing grows a seam to
get wrong. A consumer with its own names for the seats maps them once, at its
own edge.

=head2 The stages of a bout, and who is on turn

C<phase> is derived and never stored, because a stored stage is a second copy
of the truth:

=over 4

=item * an attack card with no answer, in a bout nobody has taken, is C<defend>

=item * a bout the defender has taken is C<pile_on>

=item * anything else is C<attack>

=back

C<turn> follows from it: the defender defends, and the attacker does
everything else. B<Exactly one seat is on turn at every position.>

=head2 A position with no choice in it is resolved by the engine

An attacker with nothing legal to throw is not deciding anything by saying
they are done, and a defender who cannot beat the card in front of them is not
deciding anything by picking it up. Both are resolved inside C<apply>, so
neither costs a move, an event or a turn. The consumer sees the bout end, and
the C<how> of C<bout_end> says which of the rules' reasons ended it.

=head2 The refill, and who draws first

    After a bout is complete, all players who have fewer than six cards must
    if possible replenish their hands to six by drawing sufficient cards from
    the top of the talon. The attacker replenishes first ... and finally the
    defender.

The order is not decoration. When the talon holds one card it goes to the
seat that attacked, and the other ends the deal a card short, so the seat
that beats off a bout draws first for the rest of the deal.

The seat that attacked in the bout that just ended draws first, which is not
always the seat that attacks next: a defender who beats off an attack becomes
the next attacker but still draws second.

C<refill> is emitted after every bout, zeros included, because a consumer
that replays a game compares event streams and a stream that omits its no-ops
is a different stream. It carries counts and not cards: which cards were
drawn is a function of the seed and the draws already made, so a payload that
never held them cannot leak them.

=head2 The exchange, and the one place this engine departs from the page

    If you are dealt the lowest trump (the six) or if you draw it from the
    talon, you are allowed to exchange it for the face up trump, placing your
    six of trumps under the talon and adding the turned up trump to your
    hand, at any time before the talon is exhausted.

B<At any time> is the departure. Taken literally it is a move by a seat that
is not on turn, and the source goes further still, allowing the holder to
demand the exchange after another seat has already drawn the turn-up. This
engine offers C<swap> only to the seat on turn, and only while the turn-up is
still in the talon.

The cost is one position: the seat that draws the six in the same refill
that hands the other seat the turn-up never gets its chance. The gain is that
every position in the game waits on exactly one seat, which is what makes the
engine usable by a consumer that has one deadline per turn.

The exchange stays a real move rather than being applied automatically. The
trump six is a cheap attack card that forces the defender to spend a trump on
it, so a seat with a strong trump holding may rationally keep it, and
"declining is never right" is not true here.

=head2 The trump six has a pedigree

    The six of trumps can only be exchanged by its original holder; if you
    acquire it from another player (as one of the cards you pick up when
    attacked) you cannot exchange it.

C<six_owner> is the seat that was dealt the six or drew it from the talon. It
is not cleared when the six is played: a seat that attacks with it, is beaten,
and picks the whole bout back up is holding the card it was dealt, and may
still exchange it. It is cleared for good the moment the B<other> seat comes
to hold it, and after the exchange itself.

C<can_swap> then asks three questions: is this seat the owner, does it still
hold the six, and is the turn-up still in the talon.

If the turn-up B<is> the six of trumps, which is one deal in nine, nobody was
dealt it and nobody can draw it before the talon is empty, so C<six_owner> is
undef for the whole deal and the exchange never arises. An engine that offered
it would exchange the card for itself.

=head2 Errors are returned, not thrown

C<apply> returns either a list of events or a single
L<Game::Durak::Error>. A state that cannot be reached dies instead: the
defending stage with nothing to beat, a bout opened against an empty hand, a
card that is not a card.

=head1 EVENTS

C<apply> returns the events its move caused, in order, and appends them to
C<history>. A player's move is one event with a C<seat>; everything the table
did in consequence has none.

    { kind => 'attack',   seat => 1, card => 14 }
    { kind => 'beat',     seat => 2, card => 17 }
    { kind => 'take',     seat => 2 }
    { kind => 'done',     seat => 1 }
    { kind => 'swap',     seat => 1 }
    { kind => 'resign',   seat => 1 }
    { kind => 'bout_end', taken => 0, how => 'done',
      cards => 4, discard => 4, next_attacker => 2 }
    { kind => 'refill',   drawn => { 1 => 2, 2 => 0 }, talon => 18 }
    { kind => 'out',      seat => 1 }
    { kind => 'game_end', outcome => 'fool', fool => 2,
      places => { 1 => 1, 2 => 2 } }

C<swap> carries no card. Both of them are public: everyone can see the
turn-up, and the only card that may be exchanged for it is the trump six.

C<how> is one of:

=over 4

=item * C<done>, the attacker said so

=item * C<exhausted>, the attacker had nothing legal left to throw

=item * C<capped>, the attack reached six cards or the defender's hand

=item * C<spent>, the defender beat everything and has nothing left

=item * C<taken>, the defender picked the bout up

=back

There is no C<deal> event. The deal is a pure function of the seed and the
deal number, so a consumer that stores one stores it as the seed it already
has.

=head1 METHODS

=head2 build

    Game::Durak->build(seed => $seed, number => 1, seats => 2);

A dealt game, or an error: C<no_seed> unless the seed is exactly 32 bytes,
C<bad_deal> for a deal number that does not count from one, C<bad_seats> for
anything but two. The first bout is open when it returns.

=head2 seed, number, trump, trump_card

What the deal was made from and what it turned up. The trump card is face up
and is still the last card of the talon. It is the one card of the deal that
can change: an exchange puts the trump six there instead.

=head2 six_of_trumps, turn_up_left, six_owner, can_swap

The id of the six of the trump suit; whether the turn-up is still in the
talon; the seat that may exchange that six, or undef; and whether a given
seat may do it now.

=head2 hands, talon, discard, bout, over, result, history

The state. C<hands> is a hashref of seat to a sorted arrayref of card ids,
C<talon> is the draw order with the turn-up last, C<discard> is a B<count>
and never a list, C<bout> is the open L<Game::Durak::Bout> or undef,
C<result> is undef until the deal ends and then the hashref
L<Game::Durak::Result> built, and C<history> is every event so far.

A result is set once. Setting a second one dies rather than overwriting the
first, because a deal that ends twice is a bug in the caller and not a state
worth carrying.

The discard is a count because the rules say a player may not look through
it, and an engine that offers the list invites a consumer to show it.

=head2 hand_of, count_of, talon_left, seats

A seat's cards, how many it holds, how many cards are left to draw, and the
seat numbers.

=head2 phase, turn

The stage of the bout and the seat it is waiting on. Both are derived.

=head2 view

    my $view = $game->view($seat);

Everything that seat can see, and nothing else: its own hand, the bout laid
out as attack and answer pairs, the trump, the turn-up while it is in the
talon, the size of the talon and of the heap, how many cards each seat holds,
whether this seat may exchange, its legal moves, and the result once there is
one.

What it never carries is the other hand, the talon in order, which card the
turn-up is once it has been drawn, the contents of the heap, the seed, or
whether the B<other> seat may exchange, which would say that seat holds the
trump six.

It also carries C<ply>, the number of events so far, which is what lets a bot
draw a reproducible word for the position without being handed the history.

This is the structure L<Game::Durak::Bot> and L<Game::Durak::Search> take,
and it is the one a consumer sends to a screen.

=head2 legal

    $game->legal($seat);

What that seat may do now, as an arrayref of C<{ kind, card }>, and empty for
the seat that is not on turn. C<take> is offered only when a beat is also
possible, and C<done> only when a throw is also possible, because a position
with one answer is not a decision and the engine has already resolved it.

B<An available exchange is a second answer, and it opens both of them again.>
A seat that cannot beat but may exchange is offered the exchange and the
take, not the exchange alone: otherwise the rules would compel a player to
give up the trump six, which they are nowhere required to do.

=head2 apply

    my @events = $game->apply($seat, { kind => 'attack', card => 14 });

The move, or an error. Refusals: C<game_over>, C<not_your_turn>,
C<not_legal> for a move this engine does not have, C<wrong_phase> for one that
does not fit the stage, C<card_not_held>, C<bout_full>, C<rank_not_in_bout>,
C<beats_nothing>, C<must_attack>, C<not_the_six> for an exchange that is not
this seat's to make, and C<talon_shut> for one asked after the turn-up has
been drawn.

An exchange does not end the turn: the seat that made it still has the attack
or the defence in front of it.

B<C<resign> is the one move either seat may make at any time>, on turn or
not, because a person who has stopped playing is not waiting for their turn
to say so. It is not in C<legal>, which answers what the rules of durak offer
the seat on turn, and giving up is not one of them: the seat that resigns is
the fool, whatever it was holding, and the cards are left where they lay so
that a finished deal can still be read back.

=head2 replay

    my $out = Game::Durak->replay(seed => $seed, moves => $moves);
    $out->{game};      # the deal, played out
    $out->{events};    # everything that happened, in order

The move log is the canonical serialisation of a deal, not the position: a
seed and a list of C<{ seat, kind, card }> is the whole truth, and everything
else in the event stream is recomputed from it rather than stored.

Takes what L</build> takes, plus C<moves>. Returns an error at the first move
the rules refuse, which is what makes the log trustworthy: a consumer cannot
store a move this engine would not have made, so a forged card comes back as
C<card_not_held> rather than as a different game.

=head2 moves_of, is_move

    Game::Durak->moves_of($game->history);    # just the moves
    Game::Durak->is_move('bout_end');         # 0

Which events are somebody's move and which are what the table did in
consequence. The six that are moves are the six a consumer stores.

=head1 SEE ALSO

L<Game::Durak::Card>, L<Game::Durak::Deck>, L<Game::Durak::Bout>,
L<Game::Durak::Rules>, L<Game::Durak::Result>, L<Game::Durak::Search>,
L<Game::Durak::Bot>, L<Game::Durak::Terminal>, L<Game::Durak::Error>.

The rules: L<https://www.pagat.com/beating/podkidnoy_durak.html>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
