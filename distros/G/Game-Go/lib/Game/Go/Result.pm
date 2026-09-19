package Game::Go::Result;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Go::Rules;

our $VERSION = '0.01';

our @RESULTS;
BEGIN { @RESULTS = qw(score resign timeout abandoned) }

has winner => (is => 'ro');
has result => (is => 'ro', isa => Str);

has scored_by => (is => 'ro');

has scores    => (is => 'ro', isa => HashRef, default => {});
has territory => (is => 'ro', isa => HashRef, default => {});
has prisoners => (is => 'ro', isa => HashRef, default => {});
has area      => (is => 'ro', isa => HashRef, default => {});

has komi => (is => 'ro', default => 0);
has dame => (is => 'ro', default => 0);

sub BUILD {
	my ($self) = @_;
	my $r = $self->result;
	die "Game::Go::Result: no such result '" . (defined $r ? $r : '(undef)') . "'"
		unless defined $r && grep { $_ eq $r } @RESULTS;
	return;
}

sub results { @RESULTS }

sub scored { $_[0]->result eq 'score' ? 1 : 0 }

sub margin {
	my ($self) = @_;
	return undef unless $self->scored;
	my $b = $self->scores->{ Game::Go::Rules::BLACK };
	my $w = $self->scores->{ Game::Go::Rules::WHITE };
	return undef unless defined $b && defined $w;
	return abs($b - $w);
}

sub places {
	my ($self) = @_;
	my ($B, $W) = (Game::Go::Rules::BLACK, Game::Go::Rules::WHITE);
	return { $B => 1, $W => 1 } unless defined $self->winner;
	return $self->winner == $B ? { $B => 1, $W => 2 } : { $B => 2, $W => 1 };
}

sub stringify {
	my ($self) = @_;
	my $r = $self->result;

	return 'the game was abandoned' unless defined $self->winner;

	my $who = ucfirst Game::Go::Rules::colour_name($self->winner);
	return "$who wins by resignation" if $r eq 'resign';
	return "$who wins on time"        if $r eq 'timeout';

	my $by = $self->margin;
	return "$who wins" unless defined $by;
	my $how = $self->scored_by && $self->scored_by eq 'area'
		? ' (scored by area, the players did not agree)' : '';
	return "$who wins by $by$how";
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::Result - who won, by how much, and by what

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $r = $game->result;

    $r->winner;       # BLACK, WHITE, or undef
    $r->result;       # score | resign | timeout | abandoned
    $r->scored_by;    # territory | area, when it was counted
    $r->margin;       # 6.5
    say $r->stringify;

=head1 DESCRIPTION

=head2 There are four results and no fifth

C<score>, C<resign>, C<timeout>, C<abandoned>. The site's C<games.result> column
is CHECK-constrained to exactly those, so a game the players could not agree is a
C<score> with C<< scored_by => 'area' >> beside it rather than a new kind of
result. Inventing a fifth would have meant a migration touching the ratings, the
leaderboards and the log page of every game on the site.

=head2 There is no draw

Komi is fractional, so the two scores can never be equal and a jigo cannot
happen. Article 10.2 permits one ("If both players have the same amount the game
is a draw, which is called a 'jigo'"), and the half point is the device that
removes it. Set an integer komi and a draw becomes reachable again; the suite
asserts it cannot happen at the shipped value, so the day somebody changes it a
test says what happened rather than a game ending in a way nothing can record.

=head1 ATTRIBUTES

=head2 winner

C<BLACK>, C<WHITE>, or undef when the game was abandoned.

=head2 result

One of the four above.

=head2 scored_by

C<territory> when the players agreed the dead stones, C<area> when they could not
and the disputes ran out. Undef when the game was not counted at all.

It is here, and in the site's view, because a player looking at their game
history is entitled to know their game was scored by a rule nobody agreed to.

=head2 scores

The final pair, keyed by colour. This is Article 10.2's arithmetic: each
player's territory less the prisoners the B<opponent> holds, plus komi for white.

=head2 territory, prisoners, area

The workings, so a page can show them rather than printing a margin with no
explanation. C<territory> is before the prisoner fill; C<area> is the
Tromp-Taylor score of the same position, which is what the game would have been
worth under the other ruleset.

=head2 komi, dame

The komi in use, and how many empty points reached both colours.

=head1 METHODS

=head2 results

The four result values, as a list.

=head2 scored

Whether this game was counted.

=head2 margin

The absolute difference between the two scores, or undef when the game was not
counted.

=head2 places

The finishing order, keyed by colour, for a site that ranks players. Both first
when there is no winner.

=head2 stringify

A sentence, and it says when the game was scored by area, because that is the
case a player will otherwise write in about.

=head1 SEE ALSO

L<Game::Go>, L<Game::Go::Scoring>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
