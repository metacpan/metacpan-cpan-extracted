package Game::Floppy::Error;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar -types;

our $VERSION = '0.09';

our (@CODES, %MESSAGE);

BEGIN {
	@CODES = qw/ not_active already_flapped /;

	%MESSAGE = (
		not_active      => 'this game has finished',
		already_flapped => 'one flap a tick',
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
	Carp::croak("Game::Floppy::Error: '" . (defined $code ? $code : 'undef')
		. "' is not a code")
		unless defined $code && $MESSAGE{$code};
	return;
}

sub of {
	my ($class, $code) = @_;
	Carp::croak("Game::Floppy::Error: '" . (defined $code ? $code : 'undef')
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

Game::Floppy::Error - a refused flap, returned rather than thrown

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    $game->flap or do {
        my $error = $game->error;
        print $error->code;       # already_flapped
        print $error->message;    # one flap a tick
    };

=head1 DESCRIPTION

L<Game::Floppy> refuses a flap by returning 0 and keeping one of these where
L<Game::Floppy/error> can find it. Nothing is thrown. The codes are
C<not_active> and C<already_flapped>.

=head1 METHODS

=head2 of

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
