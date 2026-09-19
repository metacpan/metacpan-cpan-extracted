package Game::Go::Marking;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Go::Rules;

our $VERSION = '0.01';

has proposer => (is => 'rw');
has answerer => (is => 'rw');

has proposed => (is => 'rw', default => 0);

has dead => (is => 'rw', isa => HashRef, default => {});
has seki => (is => 'rw', isa => HashRef, default => {});

sub turn { $_[0]->proposed ? $_[0]->answerer : $_[0]->proposer }

sub dead_points { [ sort { $a <=> $b } keys %{ $_[0]->dead } ] }
sub seki_points { [ sort { $a <=> $b } keys %{ $_[0]->seki } ] }

sub is_dead { $_[0]->dead->{ $_[1] } ? 1 : 0 }
sub is_seki { $_[0]->seki->{ $_[1] } ? 1 : 0 }

sub toggle_dead {
	my ($self, $id) = @_;
	if ($self->dead->{$id}) { delete $self->dead->{$id}; return 0 }
	$self->dead->{$id} = 1;
	return 1;
}

sub toggle_seki {
	my ($self, $pt) = @_;
	if ($self->seki->{$pt}) { delete $self->seki->{$pt}; return 0 }
	$self->seki->{$pt} = 1;
	return 1;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::Marking - the confirmation phase, which Article 9 requires

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    # reached through the game, not built directly
    my $m = $game->marking;

    $m->proposer;       # the colour whose proposal it is
    $m->turn;           # the colour to speak now: one, always
    $m->dead_points;    # the chains proposed dead

=head1 DESCRIPTION

State for the phase between the last move and the score.

Two consecutive passes B<stop play>. They do not end the game. Article 9.2 ends
it, "through confirmation and agreement by the two players about the life and
death of stones and territory", and that is a negotiation rather than a
computation.

=head2 It is sequential, and the site is the reason

The obvious design has both players confirming, so both seats wait. That would
B<void finished games>. The site applies C<sys abandon> when a deadline passes
with two seats waiting, and its contract says so in as many words: "one seat
waiting forfeits, two waiting is abandoned". A game that has reached this phase
has been played to the end, possibly over a week, and voiding it because one
player stopped answering is the worst result the site can produce.

So: the proposer marks and says C<done>, then the answerer accepts or disputes.
Exactly one seat is waiting in every reachable state.

=head2 Nothing is proposed dead

The default mark set is empty. A dead-stone proposal is a life-and-death solver,
and this distribution does not have one. An empty set is also the right answer
for a game played out properly, so the common case is C<done> then C<accept>.

What the engine does know is Benson's unconditionally-alive set, and it uses it
as a B<veto>: a chain that is alive whatever its owner does cannot be agreed
dead. See L<Game::Go/"mark">.

=head1 ATTRIBUTES

=head2 proposer, answerer

The two colours, in their roles for this round.

=head2 proposed

True once the proposer has said C<done>. Before that the answerer has nothing to
answer.

=head2 dead

The chains marked dead, as a hashref keyed by each chain's canonical point.

=head2 seki

The points marked as seki, as a hashref. Article 8 gives seki no territory, not
even its eye points, and no flood fill can see that on its own, so seki is an
agreed fact rather than a detected one. The region a marked point belongs to is
resolved by the scorer.

=head1 METHODS

=head2 turn

The colour to speak now: the proposer until C<done>, the answerer afterwards.
B<One colour, never two.>

=head2 dead_points, seki_points

The marks as sorted arrayrefs.

=head2 is_dead, is_seki

=head2 toggle_dead, toggle_seki

Set or clear one mark, returning its new state.

=head1 SEE ALSO

L<Game::Go>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
