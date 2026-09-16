package Game::Schnapsen::Error;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

my %MESSAGE = (
    bad_variant   => 'that is not a game this engine plays',
    no_seed       => 'a deal needs a seed',
    bad_deal      => 'a deal number counts from one',
    deal_over     => 'the deal is over',
    game_over     => 'the match is over',
    not_your_turn => 'it is not your turn',
    not_legal     => 'the rules do not offer that',
    not_held      => 'that card is not in your hand',
    must_follow   => 'you must follow suit, and beat the card led if you can',
    must_lead     => 'you must lead one of the two cards you married',
    no_marriage   => 'you do not hold that marriage',
    no_exchange   => 'you cannot exchange for the trump card now',
    cannot_close  => 'the talon cannot be closed now',
    cannot_claim  => 'you may only claim just after taking a trick or declaring a marriage',
);

has code    => (is => 'ro', isa => Str);
has message => (is => 'ro', isa => Str);

sub new_code {
    my ($class, $code) = @_;
    return $class->new(
        code    => $code,
        message => $MESSAGE{$code} // $code,
    );
}

sub codes { return sort keys %MESSAGE }

1;

__END__

=head1 NAME

Game::Schnapsen::Error - what the rules refuse, as a code

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $bad = Game::Schnapsen::Variant::check_variant('bezique');
    if ($bad) {
        $bad->code;       # 'bad_variant'
        $bad->message;    # 'that is not a game this engine plays'
    }

=head1 DESCRIPTION

The engine returns its refusals rather than throwing them, so a caller decides
what its users read. C<die> is reserved for programmer error: a card id that is
not a card, or a variant name that reached a rules function without being
checked at the boundary.

The code is the part a caller should branch on. A consumer maps these to its own
vocabulary, and should map an unknown code to its most general refusal rather
than letting it escape, so that a code added here later degrades instead of
crashing.

=head1 METHODS

=head2 new_code

    Game::Schnapsen::Error->new_code('bad_variant');

Builds an error from a code, filling in the message.

=head2 code

The short code.

=head2 message

A sentence, for a terminal.

=head2 codes

Every code this class knows, sorted. A caller mapping codes to its own
vocabulary can use this to check it has covered them all.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
