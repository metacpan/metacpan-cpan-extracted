package Game::Dominoes::Layout;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Dominoes::Play;

our $VERSION = '0.01';

our @ARMS = qw/L R U D/;

has line => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

has spinner_index => (
	is => 'rw',
	isa => Int
);

has u => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

has d => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

sub is_empty {
	return scalar @{ $_[0]->line } ? 0 : 1;
}

sub count {
	my ($self) = @_;
	return scalar(@{ $self->line }) + scalar(@{ $self->u }) + scalar(@{ $self->d });
}

sub tiles {
	my ($self) = @_;
	return [ map { $_->{tile} } @{ $self->line }, @{ $self->u }, @{ $self->d } ];
}

sub pips {
	my ($self) = @_;
	my $total = 0;
	$total += $_->pips for @{ $self->tiles };
	return $total;
}

sub spinner {
	my ($self) = @_;
	my $i = $self->spinner_index;
	return undef unless defined $i;
	return $self->line->[$i]{tile};
}

sub sides_covered {
	my ($self) = @_;
	my $i = $self->spinner_index;
	return 0 unless defined $i;
	my $last = $#{ $self->line };
	return ($i > 0 ? 1 : 0) + ($i < $last ? 1 : 0);
}

sub arms_open {
	my ($self) = @_;
	return ('L') if $self->is_empty;
	return ('L', 'R') unless defined $self->spinner_index && $self->sides_covered == 2;
	return @ARMS;
}

sub face_of {
	my ($self, $arm) = @_;
	return undef unless defined $arm && grep { $_ eq $arm } $self->arms_open;
	return undef if $self->is_empty;
	return $self->line->[0]{left} if $arm eq 'L';
	return $self->line->[-1]{right} if $arm eq 'R';
	my $arms = $arm eq 'U' ? $self->u : $self->d;
	return scalar @$arms ? $arms->[-1]{outer} : $self->spinner->high;
}

sub open_ends {
	my ($self) = @_;
	return () if $self->is_empty;
	return map { $self->face_of($_) } $self->arms_open;
}

sub ends {
	my ($self) = @_;
	return () if $self->is_empty;

	my $line = $self->line;
	if (@$line == 1 && !@{ $self->u } && !@{ $self->d }) {
		return ({
			arm  => 'L',
			tile => $line->[0]{tile},
			face => $line->[0]{left},
			sole => 1,
		});
	}

	my @ends = (
		{ arm => 'L', tile => $line->[0]{tile},  face => $line->[0]{left},   sole => 0 },
		{ arm => 'R', tile => $line->[-1]{tile}, face => $line->[-1]{right}, sole => 0 },
	);
	for my $arm (qw/U D/) {
		my $arms = $arm eq 'U' ? $self->u : $self->d;
		next unless @$arms;
		push @ends, {
			arm  => $arm,
			tile => $arms->[-1]{tile},
			face => $arms->[-1]{outer},
			sole => 0,
		};
	}
	return @ends;
}

sub clone {
	my ($self) = @_;
	return ref($self)->new(
		line => [ map { { %$_ } } @{ $self->line } ],
		u    => [ map { { %$_ } } @{ $self->u } ],
		d    => [ map { { %$_ } } @{ $self->d } ],
		(defined $self->spinner_index
			? (spinner_index => $self->spinner_index) : ()),
	);
}

sub can_place {
	my ($self, $tile, $arm) = @_;
	return 0 unless ref $tile;
	return 0 unless defined $arm && grep { $_ eq $arm } $self->arms_open;
	return 1 if $self->is_empty;
	return $tile->has_face($self->face_of($arm));
}

sub place {
	my ($self, $tile, $arm) = @_;
	die 'Game::Dominoes::Layout: place wants a tile' unless ref $tile;
	$arm = 'L' unless defined $arm;
	die "Game::Dominoes::Layout: arm '$arm' is not open"
		unless grep { $_ eq $arm } $self->arms_open;
	die 'Game::Dominoes::Layout: ' . $tile->stringify . " does not match arm $arm"
		unless $self->can_place($tile, $arm);

	if ($self->is_empty) {
		$self->line([ { tile => $tile, left => $tile->high, right => $tile->low } ]);
		$self->spinner_index(0) if $tile->is_double;
		return Game::Dominoes::Play->new(
			tile    => $tile,
			arm     => 'L',
			spinner => $tile->is_double,
			ends    => [ $self->open_ends ],
		);
	}

	my $matched = $self->face_of($arm);
	my $showing = $tile->other($matched);
	my $made_spinner = ($tile->is_double && !defined $self->spinner_index) ? 1 : 0;

	if ($arm eq 'L') {
		unshift @{ $self->line }, { tile => $tile, right => $matched, left => $showing };
		$self->spinner_index($self->spinner_index + 1) if defined $self->spinner_index;
		$self->spinner_index(0) if $made_spinner;
	}
	elsif ($arm eq 'R') {
		push @{ $self->line }, { tile => $tile, left => $matched, right => $showing };
		$self->spinner_index($#{ $self->line }) if $made_spinner;
	}
	else {
		my $arms = $arm eq 'U' ? $self->u : $self->d;
		push @$arms, { tile => $tile, inner => $matched, outer => $showing };
	}

	return Game::Dominoes::Play->new(
		tile    => $tile,
		arm     => $arm,
		matched => $matched,
		showing => $showing,
		spinner => $made_spinner,
		ends    => [ $self->open_ends ],
	);
}

1;

__END__

=head1 NAME

Game::Dominoes::Layout - the tiles on the table, and where another may go

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Game::Dominoes::Layout;

	my $layout = Game::Dominoes::Layout->new;

	$layout->place($spinner, 'L');   # 5-5 opens
	$layout->arms_open;              # ('L', 'R'): the arms are shut
	$layout->place($tile, 'L');
	$layout->place($other, 'R');
	$layout->arms_open;              # ('L', 'R', 'U', 'D'): both sides covered

	$layout->open_ends;              # the faces a tile may be matched against
	$layout->ends;                   # the same ends, as the scorer needs them

=head1 DESCRIPTION

The geometry, and nothing else. This class knows where a tile may physically
go; whether a player may put it there is L<Game::Dominoes>, and what it scores
is L<Game::Dominoes::Scoring>.

=head2 The vocabulary, which is the opposite of the intuitive one

A double is laid crosswise, its long axis across the line of play. Its two
B<long sides> face along the line, so a tile played against a side continues
the main line. Its two B<short ends> stick out, and those are the extra arms.

So the rule "the sides before the ends" means B<the main line must be extended
in both directions before either perpendicular arm opens>, which is the
reverse of what the words suggest. Getting this backwards produces an engine
that opens the arms immediately, and the tactical shape of All Fives collapses
when it does.

The arms are named C<L> and C<R> for the two directions of the main line, and
C<U> and C<D> for the two off the spinner. Those names are what the notation
prints and what the event log stores.

=head2 The spinner, and why the line is one array

The spinner is the first double played, wherever it lands, and only the first.
Rather than four arms growing from a root, the main line is one ordered array
with the spinner at a known index. The contested rule then becomes arithmetic:
a side is covered when the line runs past the spinner in that direction, so
C<sides_covered> is two comparisons and not a special case.

A spinner played as the opening tile covers neither side. A spinner played
onto an existing line covers one immediately, because the tile it was laid
against is already against one of its sides. Both fall out of the index.

A later double is not a spinner. It is laid crosswise like any double and the
line runs straight through it, and it never blocks.

=head1 PROPERTIES

=head2 line

	$layout->line;

The main line, left to right, as C<{ tile, left, right }> entries where C<left>
and C<right> are the faces pointing that way.

=head2 spinner_index

	$layout->spinner_index;

Where the spinner sits in C<line>, or undef before a double is played.

=head2 u, d

	$layout->u;

The arms off the spinner's short ends, as C<{ tile, inner, outer }> entries
growing outward.

=head1 FUNCTIONS

=head2 is_empty, count, tiles, pips

	$layout->is_empty;
	$layout->count;    # tiles on the table
	$layout->tiles;    # all of them, as an arrayref
	$layout->pips;     # their pips, for the 168 invariant

=head2 spinner

	$layout->spinner;

The spinner tile, or undef if no double has been played.

=head2 sides_covered

	$layout->sides_covered;   # 0, 1 or 2

How many of the spinner's long sides carry a tile. Zero without a spinner.
The perpendicular arms open at two.

=head2 arms_open

	$layout->arms_open;   # ('L', 'R')

Which arms will accept a tile now. Just C<L> on an empty table, which is where
the opening tile goes by convention; C<L> and C<R> once there is a line; all
four once the spinner has both sides covered.

=head2 face_of

	$layout->face_of('L');   # 6

The face that arm is showing, and so what a tile must carry to go there. Undef
when the arm is not open. An empty C<U> or C<D> shows the spinner's own face.

=head2 open_ends

	$layout->open_ends;   # (6, 4)

The faces a tile could be matched against right now. This is for legality.
What an end is B<worth> is a different question with a different answer: see
C<ends>.

=head2 ends

	$layout->ends;   # ({ arm, tile, face, sole }, ...)

The open ends as the scorer needs them, one entry per end that exists. This
reports geometry and never a total, because what an end is worth is contested
and belongs in L<Game::Dominoes::Scoring>: a double at an end counts both its
halves, and a spinner stops counting once both its sides are covered.

Neither of those needs a special case here. A spinner with both sides covered
is no longer at an end, so it simply does not appear in this list.

C<sole> marks a single tile on the table, which is one end and not two, so
that its two faces are not counted twice.

=head2 clone

	->clone;

A copy with its own arrays, for trying a play without committing to it. The
tiles inside are immutable and shared.

=head2 can_place

	$layout->can_place($tile, 'L');

Whether that tile may physically go on that arm.

=head2 place

	my $play = $layout->place($tile, 'L');

Puts the tile on the arm and returns the L<Game::Dominoes::Play>. Dies on an
illegal placement, which is programmer error: a player's mistake is refused
further up by L<Game::Dominoes> as a returned error object, and nothing a
player can do reaches here without C<can_place> having said yes.

=head1 SEE ALSO

L<Game::Dominoes::Play>, what this returns; L<Game::Dominoes::Tile>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Layout

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
