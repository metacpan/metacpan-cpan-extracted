package Game::Floppy::Result;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar -types;

our $VERSION = '0.09';

our @CAUSES = qw/ ground sky tube quit /;

my %IS_CAUSE = map { $_ => 1 } @CAUSES;

my %SENTENCE = (
	ground => 'fell to the ground',
	sky    => 'flew off the top',
	tube   => 'hit a tube',
	quit   => 'quit',
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

has tubes => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has ticks => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

sub BUILD {
	my ($self) = @_;

	my $cause = $self->cause;
	Carp::croak("Game::Floppy::Result: '" . (defined $cause ? $cause : 'undef')
		. "' is not a cause")
		unless defined $cause && $IS_CAUSE{$cause};

	for my $name (qw/ score tubes ticks /) {
		my $value = $self->$name;
		Carp::croak("Game::Floppy::Result: $name must be a whole number, not "
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
	my $tail = sprintf '%s at %d points after %d ticks', $SENTENCE{ $self->cause },
		$self->score, $self->ticks;
	return $self->died ? "Game over: $tail" : ucfirst $tail;
}

1;

__END__

=head1 NAME

Game::Floppy::Result - how a game of Floppy ended

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    my $result = $game->result;

    print $result->cause;        # tube
    print $result->score;        # 300
    print $result->stringify;    # Game over: hit a tube at 300 points after 563 ticks

=head1 DESCRIPTION

L<Game::Floppy/result> hands one of these back once the game has finished.

=head1 METHODS

=head2 cause

C<ground>, C<sky>, C<tube> or C<quit>.

=head2 score, tubes, ticks

The score, tubes passed, and ticks taken.

=head2 died

1 unless the cause is C<quit>.

=head2 causes

Every cause.

=head2 stringify

One sentence: "Game over: hit a tube at 300 points after 563 ticks", "Game
over: fell to the ground ...", "Game over: flew off the top ...", or "Quit at
300 points after 563 ticks".

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
