package Game::Gin::Card;

use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(rank_of suit_of deadwood_of name_of long_name_of id_of CARDS);

use constant CARDS => 52;

my @SUITS = qw(S H D C);
my %SUIT_NAME = (S => 'spades', H => 'hearts', D => 'diamonds', C => 'clubs');

my @RANK_CHAR = ('', 'A', 2 .. 9, 'T', 'J', 'Q', 'K');
my %RANK_NAME = (1 => 'ace', 11 => 'jack', 12 => 'queen', 13 => 'king', 10 => 'ten');

my @DEADWOOD = (0, 1, 2 .. 9, 10, 10, 10, 10);

sub _check {
    my ($id) = @_;
    die 'Game::Gin::Card: no card has id ' . (defined $id ? "'$id'" : 'undef') . "\n"
        unless defined $id && $id =~ /\A[1-9][0-9]*\z/ && $id >= 1 && $id <= CARDS;
    return $id;
}

sub rank_of     { my $id = _check($_[0]); return ($id - 1) % 13 + 1 }
sub suit_of     { my $id = _check($_[0]); return $SUITS[ int(($id - 1) / 13) ] }
sub deadwood_of { return $DEADWOOD[ rank_of($_[0]) ] }

sub name_of {
    my ($id) = @_;
    return $RANK_CHAR[ rank_of($id) ] . suit_of($id);
}

sub long_name_of {
    my ($id) = @_;
    my $r = rank_of($id);
    return ($RANK_NAME{$r} // $r) . ' of ' . $SUIT_NAME{ suit_of($id) };
}

my %ID;
for my $id (1 .. CARDS) { $ID{ name_of($id) } = $id }

sub id_of {
    my ($name) = @_;
    return undef unless defined $name;
    return $ID{ uc $name };
}

1;

__END__

=head1 NAME

Game::Gin::Card - a card is an integer, and everything else is derived

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Gin::Card qw(rank_of suit_of deadwood_of name_of id_of);

    rank_of(1);          # 1, an ace
    suit_of(1);          # 'S'
    deadwood_of(1);      # 1
    name_of(1);          # 'AS'
    id_of('AS');         # 1

    deadwood_of(13);     # 10, a king
    name_of(52);         # 'KC'

=head1 DESCRIPTION

Cards are integers 1 to 52, suit-major: 1 to 13 are spades ace to king, 14 to
26 hearts, 27 to 39 diamonds, 40 to 52 clubs. A hand is therefore a list of
small integers and a deal is a permutation.

=head2 The ace is low and only low

A-2-3 is a run and Q-K-A is not. Ranks are 1 to 13 with no wraparound
anywhere, so the invalid run cannot be formed by arithmetic. L<Game::Gin::Meld>
depends on this.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 rank_of

The rank as 1 to 13, where 1 is an ace and 13 a king. Dies for an id that is
not a card.

=head2 suit_of

One of C<S>, C<H>, C<D>, C<C>.

=head2 deadwood_of

What the card counts against you when it is not in a meld: an ace 1, a court
card 10, everything else its own number.

=head2 name_of

Two characters, rank then suit: C<AS>, C<TD>, C<QH>. Ten is C<T> so that every
card is the same width.

=head2 long_name_of

C<ace of spades>, for a sentence.

=head2 id_of

The id for a name, or undef. Case insensitive. This one parses input, so it
returns undef rather than dying.

=head2 CARDS

52, as a constant.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
