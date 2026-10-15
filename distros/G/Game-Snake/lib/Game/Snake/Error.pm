package Game::Snake::Error;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar -types;

our $VERSION = '0.13';

our (@CODES, %MESSAGE);

BEGIN {
	@CODES = qw/ same_direction reverse not_active /;

	%MESSAGE = (
		same_direction => 'the snake is already heading that way',
		reverse        => 'a snake cannot turn back on itself',
		not_active     => 'this game has finished',
	);
}

has code => (
	is  => 'ro',
	isa => Str
);

has message => (
	is  => 'ro',
	isa => Str
);

has error => (
	is      => 'ro',
	default => 1
);

sub BUILD {
	my ($self) = @_;
	my $code = $self->code;
	Carp::croak("Game::Snake::Error: '" . (defined $code ? $code : 'undef')
		. "' is not a code")
		unless defined $code && $MESSAGE{$code};
	return;
}

sub of {
	my ($class, $code) = @_;
	Carp::croak("Game::Snake::Error: '" . (defined $code ? $code : 'undef')
		. "' is not a code")
		unless defined $code && $MESSAGE{$code};
	return $class->new(code => $code, message => $MESSAGE{$code});
}

sub codes { return [@CODES] }

sub messages { return { %MESSAGE } }

sub stringify {
	my ($self) = @_;
	return $self->code . ': ' . $self->message;
}

1;

__END__

=head1 NAME

Game::Snake::Error - a refused turn, returned rather than thrown

=head1 VERSION

Version 0.13

=head1 SYNOPSIS

    $game->turn('right') or do {
        my $error = $game->error;
        print $error->code;       # reverse
        print $error->message;    # a snake cannot turn back on itself
    };

=head1 DESCRIPTION

L<Game::Snake> refuses a turn by returning 0 and keeping one of these where
L<Game::Snake/error> can find it. Nothing is thrown: a refused turn is an
ordinary thing to happen in a game, not an error in the program.

The codes are C<same_direction>, C<reverse> and C<not_active>.

=head1 METHODS

=head2 of

    my $error = Game::Snake::Error->of('reverse');

Builds the error for a code. An unknown code is a programmer error and dies.

=head2 code, message, error

The code, its sentence, and 1.

=head2 codes, messages

Every code, and every code with its sentence.

=head2 stringify

The code and the sentence, joined with a colon.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
