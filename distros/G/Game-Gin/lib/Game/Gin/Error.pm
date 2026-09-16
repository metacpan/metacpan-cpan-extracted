package Game::Gin::Error;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

my %MESSAGE = (
    hand_over      => 'the hand is over',
    not_your_turn  => 'it is not your turn',
    not_legal      => 'the rules do not offer that',
    not_held       => 'that card is not in your hand',
    just_taken     => 'you may not discard the card you have just taken',
    cannot_knock   => 'your deadwood is above the knock threshold',
    not_big_gin    => 'that hand is not big gin',
    no_seed        => 'a hand needs a seed',
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

Game::Gin::Error - what the rules refuse, as a code

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $out = $game->apply('p1', { kind => 'discard', card => $id });
    if (ref $out eq 'Game::Gin::Error') {
        $out->code;       # 'not_held'
        $out->message;    # 'that card is not in your hand'
    }

=head1 DESCRIPTION

The engine returns its refusals rather than throwing them, so a caller decides
what its users read. C<die> is reserved for programmer error.

=head1 METHODS

=head2 new_code

    Game::Gin::Error->new_code('not_held');

Builds an error from a code, filling in the message.

=head2 code

The short code, which is what a caller should branch on.

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
