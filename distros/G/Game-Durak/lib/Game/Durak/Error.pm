package Game::Durak::Error;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

my %MESSAGE = (
    no_seed          => 'a deal needs a seed',
    bad_deal         => 'a deal number counts from one',
    bad_seats        => 'this engine deals two seats',
    game_over        => 'the deal is over',
    not_your_turn    => 'it is not your turn',
    wrong_phase      => 'that move does not fit this stage of the bout',
    not_legal        => 'the rules do not offer that',
    card_not_held    => 'you do not hold that card',
    beats_nothing    => 'that card does not beat the one in front of you',
    rank_not_in_bout => 'nothing on the table has that rank',
    bout_full        => 'the attack is already as large as it may be',
    must_attack      => 'a bout has to be opened before it can be beaten off',
    not_the_six      => 'that exchange is not yours to make',
    talon_shut       => 'the turned up trump has been drawn',
);

has code    => (is => 'ro', isa => Str);
has message => (is => 'ro', isa => Str);

sub new_code {
    my ($class, $code) = @_;
    return $class->new(
        code    => $code,
        message => defined $MESSAGE{$code} ? $MESSAGE{$code} : $code,
    );
}

sub codes { return sort keys %MESSAGE }

1;

__END__

=head1 NAME

Game::Durak::Error - what the rules refuse, as a code

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $out = $game->apply(1, { kind => 'attack', card => 14 });
    if (ref $out eq 'Game::Durak::Error') {
        $out->code;       # 'rank_not_in_bout'
        $out->message;    # 'nothing on the table has that rank'
    }

=head1 DESCRIPTION

An error is B<returned and never thrown>. A move a player is not allowed to
make is an ordinary answer, not an exception: the consumer turns the code into
whatever it says to a person, and a code it has never heard of degrades to a
refusal rather than to a crash.

A state that cannot happen is the other thing entirely, and it dies. A card id
that is not a card, a suit that is not a suit, a bout opened against an empty
hand: those are bugs in the caller and they are not codes.

=head2 The codes, and why they are not the obvious names

The consumer these are written for is peer2peergames, whose own refusal table
already holds a hundred and sixty codes, so two of the obvious names are
taken and would have landed this game's refusals on another game's sentence.
C<no_swap> is the Hex swap rule ("the swap is only offered on the second
player's first turn"), so the exchange refuses with C<not_the_six> and
C<talon_shut>. C<stock_empty> says stock and belongs to a shedding game, so
the talon says C<talon_shut>.

C<must_attack> is the reachable half of what an earlier draft called
C<bout_open>. A card that is unbeaten in a bout nobody has taken B<is> the
defending stage, so a C<done> sent then is refused for the stage and never
for the unbeaten card; the one way to say you are finished when you are not
is to say it before attacking at all.

=head1 METHODS

=head2 code

The short string a consumer switches on.

=head2 message

One sentence in English, for a terminal or a log. A consumer with a
translation table of its own should use the code and ignore this.

=head2 new_code

    Game::Durak::Error->new_code('bout_full');

An error from a code. An unknown code gets itself as its message rather than
undef, so a missing entry shows up in the output instead of disappearing.

=head2 codes

Every code this engine can return, sorted. A consumer's mapping table can be
tested against it, which is how a new code is noticed before a player finds
it.

=head1 SEE ALSO

L<Game::Durak>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
