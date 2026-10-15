package Game::Snake::Result;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar -types;

our $VERSION = '0.13';

our @CAUSES = qw/ wall body full quit /;

my %IS_CAUSE = map { $_ => 1 } @CAUSES;

my %SENTENCE = (
	wall => 'hit the wall',
	body => 'ran into yourself',
	full => 'filled the board',
	quit => 'quit',
);

has cause => (
	is  => 'ro',
	isa => Str
);

has score => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has length => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has ticks => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has speed => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

sub BUILD {
	my ($self) = @_;

	my $cause = $self->cause;
	Carp::croak("Game::Snake::Result: '" . (defined $cause ? $cause : 'undef')
		. "' is not a cause")
		unless defined $cause && $IS_CAUSE{$cause};

	for my $name (qw/ score length ticks speed /) {
		my $value = $self->$name;
		Carp::croak("Game::Snake::Result: $name must be a whole number, not "
			. (defined $value ? "'$value'" : 'undef'))
			unless defined $value && $value =~ /\A[0-9]+\z/;
	}

	return;
}

sub causes { return [@CAUSES] }

sub died {
	my ($self) = @_;
	return $self->cause eq 'quit' ? 0 : 1;
}

sub stringify {
	my ($self) = @_;
	my $tail = sprintf '%s at %d points, %d long', $SENTENCE{ $self->cause },
		$self->score, $self->length;
	return $self->died ? "Game over: $tail" : ucfirst $tail;
}

1;

__END__

=head1 NAME

Game::Snake::Result - how a game of snake ended

=head1 VERSION

Version 0.13

=head1 SYNOPSIS

    my $result = $game->result;

    print $result->cause;        # wall
    print $result->score;        # 120
    print $result->stringify;    # Game over: hit the wall at 120 points, 15 long

=head1 DESCRIPTION

L<Game::Snake/result> hands one of these back once the game has finished.

=head1 METHODS

=head2 cause

C<wall>, C<body>, C<full> or C<quit>.

=head2 score, length, ticks, speed

The score, how long the snake was, how many ticks were taken, and the speed
reached, in cells a second.

=head2 died

1 unless the cause is C<quit>.

=head2 causes

Every cause.

=head2 stringify

One sentence: "Game over: hit the wall at 120 points, 15 long", or "Quit at
120 points, 15 long".

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
