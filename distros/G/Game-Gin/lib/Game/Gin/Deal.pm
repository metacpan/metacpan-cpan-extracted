package Game::Gin::Deal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Gin::Deck ();
use Game::Gin::Hand ();
use Game::Gin::Error ();
use Game::Gin::Deadwood qw(KNOCK_AT);
use Game::Gin::Scoring qw(settle);

our $VERSION = '0.01';

has seed        => (is => 'ro', isa => Str);
has number      => (is => 'ro', isa => Int);
has dealer      => (is => 'ro', isa => Str);
has hands       => (is => 'rw', isa => HashRef);
has stock       => (is => 'rw', isa => ArrayRef);
has discard     => (is => 'rw', isa => ArrayRef);
has turn        => (is => 'rw', isa => Str);
has phase       => (is => 'rw', isa => Str);
has taken       => (is => 'rw', isa => Int);
has result      => (is => 'rw', isa => HashRef);

has history     => (is => 'rw', isa => ArrayRef);

sub other { return $_[0] eq 'p1' ? 'p2' : 'p1' }

sub build {
    my ($class, %o) = @_;
    my $seed = $o{seed};
    return Game::Gin::Error->new_code('no_seed')
        unless defined $seed && length $seed == 32;

    my $number = $o{number} || 1;
    my $dealer = $o{dealer} || 'p1';
    my $pone   = other($dealer);

    my $deal = Game::Gin::Deck::deal_for($seed, $number);

    my $self = $class->new(
        seed    => $seed,
        number  => $number,
        dealer  => $dealer,
        hands   => {
            $pone   => Game::Gin::Hand->new(cards => [ @{ $deal->{non_dealer} } ]),
            $dealer => Game::Gin::Hand->new(cards => [ @{ $deal->{dealer} } ]),
        },
        stock   => [ @{ $deal->{stock} } ],
        discard => [ $deal->{upcard} ],
        turn    => $pone,
        phase   => 'upcard',
        taken   => 0,
        history => [],
        result  => undef,
    );
    return $self;
}

sub over     { return $_[0]->result ? 1 : 0 }
sub upcard   { my $d = $_[0]->discard; return @$d ? $d->[-1] : undef }
sub hand_of  { return $_[0]->hands->{ $_[1] } }
sub stock_left { return scalar @{ $_[0]->stock } }

sub legal {
    my ($self, $seat) = @_;
    return [] if $self->over;
    return [] unless defined $seat && ($self->turn // '') eq $seat;

    my $phase = $self->phase;
    return [ { kind => 'take' }, { kind => 'pass' } ] if $phase eq 'upcard';

    return [ { kind => 'draw' } ] if $phase eq 'forced_draw';

    if ($phase eq 'draw') {
        my @out = ({ kind => 'draw' });
        push @out, { kind => 'take' } if defined $self->upcard;
        return \@out;
    }

    my $hand = $self->hand_of($seat);
    my @out;
    push @out, { kind => 'big_gin' } if $hand->deadwood == 0 && $hand->full;
    for my $card (@{ $hand->cards }) {
        next if defined $self->taken && $self->taken && $card == $self->taken;
        push @out, { kind => 'discard', card => $card };
        my @rest = grep { $_ != $card } @{ $hand->cards };
        my $left = Game::Gin::Deadwood::deadwood(\@rest);
        push @out, { kind => 'discard', card => $card, knock => 1 } if $left <= KNOCK_AT;
    }
    return \@out;
}

sub apply {
    my ($self, $seat, $move) = @_;
    return Game::Gin::Error->new_code('hand_over') if $self->over;
    return Game::Gin::Error->new_code('not_your_turn')
        unless defined $seat && ($self->turn // '') eq $seat;

    my $kind = ref $move eq 'HASH' ? ($move->{kind} // '') : '';
    my $phase = $self->phase;

    my @out;
    if ($phase eq 'upcard') { @out = $self->_first_turn($seat, $kind) }
    elsif ($phase eq 'forced_draw') {
        return Game::Gin::Error->new_code('not_legal') unless $kind eq 'draw';
        @out = $self->_draw($seat);
    }
    elsif ($phase eq 'draw') {
        if    ($kind eq 'draw') { @out = $self->_draw($seat) }
        elsif ($kind eq 'take') { @out = $self->_take($seat) }
        else { return Game::Gin::Error->new_code('not_legal') }
    }
    elsif ($kind eq 'big_gin')  { @out = $self->_big_gin($seat) }
    elsif ($kind eq 'discard')  { @out = $self->_discard($seat, $move) }
    else { return Game::Gin::Error->new_code('not_legal') }

    return $out[0] if @out == 1 && ref $out[0] eq 'Game::Gin::Error';
    $self->history([ @{ $self->history || [] }, @out ]);
    return @out;
}

sub _first_turn {
    my ($self, $seat, $kind) = @_;
    return $self->_take($seat) if $kind eq 'take';
    return Game::Gin::Error->new_code('not_legal') unless $kind eq 'pass';

    my @out = ({ kind => 'pass', seat => $seat });
    if ($seat eq $self->dealer) {
        $self->turn(other($self->dealer));
        $self->phase('forced_draw');
    }
    else {
        $self->turn($self->dealer);
    }
    return @out;
}

sub _take {
    my ($self, $seat) = @_;
    my $card = $self->upcard;
    return Game::Gin::Error->new_code('not_legal') unless defined $card;
    my @pile = @{ $self->discard };
    pop @pile;
    $self->discard(\@pile);
    $self->hand_of($seat)->add($card);
    $self->taken($card);
    $self->phase('discard');
    return ({ kind => 'take', seat => $seat, card => $card });
}

sub _draw {
    my ($self, $seat) = @_;
    my @stock = @{ $self->stock };
    return Game::Gin::Error->new_code('not_legal') unless @stock;
    my $card = shift @stock;
    $self->stock(\@stock);
    $self->hand_of($seat)->add($card);
    $self->taken(0);
    $self->phase('discard');
    return ({ kind => 'draw', seat => $seat });
}

sub _discard {
    my ($self, $seat, $move) = @_;
    my $card = $move->{card};
    my $hand = $self->hand_of($seat);
    return Game::Gin::Error->new_code('not_held')  unless $hand->has_card($card);
    return Game::Gin::Error->new_code('just_taken')
        if $self->taken && $card == $self->taken;

    $hand->remove($card);
    $self->discard([ @{ $self->discard }, $card ]);
    $self->taken(0);

    my $left = $hand->deadwood;
    if ($move->{knock}) {
        return Game::Gin::Error->new_code('cannot_knock') if $left > KNOCK_AT;
        my @out = ({ kind => 'discard', seat => $seat, card => $card, knock => 1 });
        push @out, $self->_finish($seat, gin => ($left == 0 ? 1 : 0));
        return @out;
    }

    my @out = ({ kind => 'discard', seat => $seat, card => $card });

    if ($self->stock_left <= 2) {
        $self->result({ kind => 'cancelled', winner => undef, points => 0 });
        $self->turn(undef);
        $self->phase('over');
        push @out, { kind => 'cancelled' };
        return @out;
    }

    $self->turn(other($seat));
    $self->phase('draw');
    return @out;
}

sub _big_gin {
    my ($self, $seat) = @_;
    my $hand = $self->hand_of($seat);
    return Game::Gin::Error->new_code('not_big_gin')
        unless $hand->full && $hand->deadwood == 0;
    return ({ kind => 'big_gin', seat => $seat }, $self->_finish($seat, big_gin => 1));
}

sub _finish {
    my ($self, $knocker, %how) = @_;
    my $defender = other($knocker);
    my $hand = $self->hand_of($knocker);
    my $best = $hand->best;

    my $r = settle(
        knocker          => $knocker,
        defender         => $defender,
        knocker_deadwood => $best->{deadwood},
        knocker_melds    => $best->{melds},
        defender_cards   => $self->hand_of($defender)->cards,
        gin              => ($how{gin} || $how{big_gin} ? 1 : 0),
        big_gin          => ($how{big_gin} ? 1 : 0),
    );
    $self->result($r);
    $self->turn(undef);
    $self->phase('over');
    return ({ %$r, how => $r->{kind}, kind => 'hand_end' });
}

1;

__END__

=head1 NAME

Game::Gin::Deal - one hand of gin rummy, from the deal to the knock

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $deal = Game::Gin::Deal->build(seed => $bytes, number => 1, dealer => 'p1');

    $deal->turn;                        # 'p2', the non-dealer
    $deal->phase;                       # 'upcard'
    $deal->legal('p2');                 # take or pass

    my @out = $deal->apply('p2', { kind => 'take' });
    @out = $deal->apply('p2', { kind => 'discard', card => $id, knock => 1 });

    $deal->over;                        # 1
    $deal->result;                      # { winner, points, kind, ... }

=head1 DESCRIPTION

One deal. A match to 100 is many of these; keeping them apart is what makes
the first turn testable on its own.

Nothing here prints, reads a handle or calls C<rand>.

=head2 The first turn is not a normal turn

The non-dealer may take the upcard. If they decline, the dealer may. If both
decline, the non-dealer draws from the stock and may not take the card they
have just refused. Three phases rather than one condition, because each has a
different set of legal moves.

=head2 The stock is never named

A draw from the stock returns an outcome with no card in it. The stock is the
tail of the shuffled order, so the card is derivable from the seed and the
number of draws; nothing downstream has to be trusted to keep it secret,
because there is no field for it to leak from.

=head2 The hand is cancelled at two cards

When a discard leaves two cards in the stock, the hand ends and nobody scores.

=head1 METHODS

=head2 build

    Game::Gin::Deal->build(seed => $bytes, number => $n, dealer => 'p1');

Deals. Returns the deal, or a L<Game::Gin::Error> for a bad seed.

=head2 legal

The moves this seat may make now, as arrayrefs of hashrefs. Empty for the seat
not on turn and for a finished hand.

=head2 apply

    $deal->apply($seat, { kind => 'discard', card => $id });

Applies a move and returns the outcomes, or a L<Game::Gin::Error>.

=head2 turn, phase, over, result

Where the hand is. C<phase> is C<upcard>, C<forced_draw>, C<draw>, C<discard>
or C<over>.

=head2 hand_of, upcard, stock_left, discard, hands, stock

The position. C<hand_of> takes a seat and returns its L<Game::Gin::Hand>;
C<upcard> is the top of the discard pile, or undef if the pile is empty;
C<stock_left> is how many cards remain to be drawn.

=head2 history

Every outcome this deal has produced, in order. A draw outcome names no card,
so a history cannot leak the stock.

=head2 seed

The 32 bytes this deal came from.

=head2 number

Which deal of the match this is. It is part of the shuffle key, so deal two of
a match deals differently from deal one.

=head2 dealer

The seat that dealt. The other seat has the first say on the upcard.

=head2 taken

The card just taken from the discard pile, or 0. It exists so that the discard
which follows cannot simply put it back, which would be a turn that changed
nothing and a way to stall for ever.

=head2 other

The other seat.

=head1 SEE ALSO

L<Game::Gin::Scoring>, L<Game::Gin::Deadwood>, L<Game::Gin::Deck>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
