package Game::Go::Move;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Go::Rules;

our $VERSION = '0.01';

our @KINDS;
BEGIN {
	@KINDS = qw(
		play pass handicap resign
		mark unmark seki unseki done accept dispute
	);
}

our %WANTS_POINT;
BEGIN {
	%WANTS_POINT = map { $_ => 1 } qw(play handicap mark unmark seki unseki);
}

has kind   => (is => 'ro', isa => Str);
has colour => (is => 'ro');
has point  => (is => 'ro');
has caps   => (is => 'ro', isa => ArrayRef, default => []);

sub BUILD {
	my ($self) = @_;
	my $kind = $self->kind;

	die "Game::Go::Move: no such kind '" . (defined $kind ? $kind : '(undef)') . "'"
		unless defined $kind && grep { $_ eq $kind } @KINDS;

	die "Game::Go::Move: a '$kind' move takes no point"
		if !$WANTS_POINT{$kind} && defined $self->point;
	die "Game::Go::Move: a '$kind' move needs a point"
		if $WANTS_POINT{$kind} && !defined $self->point;

	die "Game::Go::Move: only a play captures, not a '$kind'"
		if $kind ne 'play' && @{ $self->caps };

	die "Game::Go::Move: a move needs a colour"
		unless Game::Go::Rules::is_colour($self->colour);

	return;
}

sub kinds { @KINDS }

sub is_pass { $_[0]->kind eq 'pass' }
sub is_play { $_[0]->kind eq 'play' }

sub captured { scalar @{ $_[0]->caps } }

sub stringify {
	my ($self) = @_;
	my $who = Game::Go::Rules::colour_name($self->colour);
	return "$who passes"  if $self->kind eq 'pass';
	return "$who resigns" if $self->kind eq 'resign';
	my $where = defined $self->point ? ' at ' . $self->point : '';
	my $took  = $self->captured ? ', taking ' . $self->captured : '';
	return $who . ' ' . $self->kind . $where . $took;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::Move - one move, of one kind

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $move = $game->play('b', $pt);

    $move->kind;        # 'play'
    $move->point;       # the padded index
    $move->caps;        # the points the captured stones came off
    $move->captured;    # how many

=head1 DESCRIPTION

A move that happened. A move that did not is a L<Game::Go::Error> instead, so a
caller holding one of these is holding something the rules allowed.

=head2 The kinds, and why there are so many

    play  pass  handicap  resign
    mark  unmark  seki  unseki  done  accept  dispute

The first four are the game. The last seven are the confirmation phase, which
exists because Article 9 of the Japanese rules does not end a game when play
stops:

    After stopping, the game ends through confirmation and agreement by the two
    players about the life and death of stones and territory.

That is a negotiation between two people, so it has moves of its own, and they
are moves rather than some separate kind of message because they go in the same
log and a replay has to reproduce them the same way.

C<handicap> is its own kind rather than a C<play> so that the log can say "black
takes five handicap stones" instead of narrating five moves nobody made, and so
that a replay can check the stones landed on the traditional points.

=head1 ATTRIBUTES

=head2 kind

One of the eleven above. Anything else dies at construction: it is programmer
error, not a refused move.

=head2 colour

C<BLACK> or C<WHITE>. Required, including on the confirmation moves, because the
log records who said it.

=head2 point

The engine's padded index, for the kinds that have one, and undef for the kinds
that do not. B<Opaque>: it is not C<row * size + col>. See
L<Game::Go/"A point is opaque">.

A move whose kind takes no point and carries one anyway dies, and so does one
whose kind needs a point and has none. That is cheap here and expensive to find
in a replay.

=head2 caps

The points the captured stones came off, as an arrayref. Only a C<play> may
carry any.

=head1 METHODS

=head2 kinds

Every kind, as a list.

=head2 is_play, is_pass

=head2 captured

How many stones this move took.

=head2 stringify

A sentence. For the log page the site writes its own, because it knows the
players' names and this does not.

=head1 SEE ALSO

L<Game::Go>, L<Game::Go::Error>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
