package Game::Dominoes::Play;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

has tile => (
	is => 'ro',
	isa => Object
);

has arm => (
	is => 'ro',
	isa => Str
);

has matched => (
	is => 'ro',
	isa => Int
);

has showing => (
	is => 'ro',
	isa => Int
);

has spinner => (
	is => 'ro',
	isa => Bool,
	default => 0
);

has ends => (
	is => 'ro',
	isa => ArrayRef,
	default => []
);

has points => (
	is => 'rw',
	isa => Int
);

sub is_opening {
	return defined $_[0]->matched ? 0 : 1;
}

sub stringify {
	my ($self) = @_;
	my $text = $self->tile->stringify . '@' . $self->arm;
	$text .= '*' if $self->spinner;
	return $text;
}

1;

__END__

=head1 NAME

Game::Dominoes::Play - one tile put on the table

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	my $play = $layout->place($tile, 'L');

	$play->tile->stringify;   # '6-4'
	$play->arm;               # 'L'
	$play->matched;           # 6, the face it was laid against
	$play->showing;           # 4, the face it leaves open
	$play->ends;              # the faces open after it
	$play->stringify;         # '6-4@L'

=head1 DESCRIPTION

An immutable record of one play, and the unit both the event log and the
notation carry.

C<points> is the exception to the immutability and is deliberately left undef
by L<Game::Dominoes::Layout>, which does geometry and knows nothing about
fives. L<Game::Dominoes::Scoring> fills it in. A play whose C<points> are
undef has not been scored yet, which is not the same as one that scored
nothing.

=head1 PROPERTIES

=head2 tile

	$play->tile;

The L<Game::Dominoes::Tile> that was played.

=head2 arm

	$play->arm;   # 'L'

Which arm it went on: C<L> or C<R> along the main line, C<U> or C<D> on the
spinner.

=head2 matched

	$play->matched;   # 6

The face it was laid against. Undef for the opening play, which is laid
against nothing.

=head2 showing

	$play->showing;   # 4

The face it leaves open. Undef for the opening play, which shows both faces.

=head2 spinner

	$play->spinner;

Whether this play made the spinner. Only the first double played does, and
the notation marks it with a star.

=head2 ends

	$play->ends;

The faces open after the play, as the layout reported them.

=head2 points

	$play->points;

What it scored, once L<Game::Dominoes::Scoring> has said. Undef until then.

=head1 FUNCTIONS

=head2 is_opening

	$play->is_opening;

Whether this was the first tile of the hand.

=head2 stringify

	$play->stringify;   # '6-4@L', or '5-5@L*' for the spinner

The play as the notation writes it.

=head1 SEE ALSO

L<Game::Dominoes::Layout>, which makes these.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Play

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
