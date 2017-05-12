package Games::Ratings::LogisticElo;

use 5.014000;
use strict;
use warnings;
use parent qw/Exporter Games::Ratings/;

our @EXPORT_OK = qw/multi_elo/;
our @EXPORT = qw//;
our $VERSION = '0.001';

use List::Util qw/sum/;

sub get_rating_change {
	my ($self) = @_;

	my $own_rating = $self->get_rating;
	my $K = $self->get_coefficient;

	my $expected = sum map {
		my $exp = ($_->{opponent_rating} - $own_rating) / 400;
		1 / (1 + 10 ** $exp)
	} $self->get_all_games;

	my $actual = sum map {
		Games::Ratings::_get_numerical_result($_->{result})
	} $self->get_all_games;

	$K * ($actual - $expected)
}

sub get_new_rating {
	my ($self) = @_;
	$self->get_rating + $self->get_rating_change
}

sub multi_elo {
	my @args = @_;
	my $K = ref $args[0] ? 15 : shift @args;

	my @newratings = map {
		my $player = __PACKAGE__->new;
		$player->set_rating($_->[0]);
		$player->set_coefficient($K);
		for my $opponent (@args) {
			$player->add_game({
				opponent_rating => $opponent->[0],
				result =>
				  $_->[1] > $opponent->[1] ? 'win' :
				  $_->[1] < $opponent->[1] ? 'loss' : 'draw'
			})
		}
		$player->get_new_rating
	} @args;

	wantarray ? @newratings : \@newratings
}

1;
__END__

=encoding utf-8

=head1 NAME

Games::Ratings::LogisticElo - calculate changes to logistic curve Elo ratings

=head1 SYNOPSIS

  use Games::Ratings::LogisticElo;
  my $player = Games::Ratings::LogisticElo->new;
  $player->set_rating(2240);
  $player->set_coefficient(15);
  $player->add_game({
    opponent_rating => 2114,
    result => 'win', ## or 'draw' or 'loss'
  });
  say 'Rating change: ' . $player->get_rating_change;
  say 'New rating: ' . $player->get_new_rating;

  use Games::Ratings::LogisticElo qw/multi_elo/;
  my @results = [2240, 3], [2114, 2], [2300, 1];
  my @new_ratings = multi_elo 15, @results;
  say 'Rating changes for this comp: ', join ', ',
    map { $new_ratings[$_] - $results[$_]->[0] } 0 .. $#results;

=head1 DESCRIPTION

This module provides methods to calculate Elo rating changes. Unlike
L<Games::Ratings::Chess::FIDE>, this Elo implementation uses the
logistic distribution instead of the standard distribution.

This module can be used both for a single player who played multiple
rated games, and for a single competition with an arbitrary number of
players.

=head1 FUNCTIONS

Games::Ratings::LogisticElo inherits from L<Games::Ratings>, see that
module's documentation for information about the inherited methods.

Nothing is exported by default, the function B<multi_elo> can be
exported on request.

=over

=item B<$self>->I<get_rating_change>

Computes and returns how much a player's rating changes after the
games added.

=item B<$self>->I<get_new_rating>

Adds the result of I<get_rating_change> to the old rating of the
player and returns this.

=item B<multi_elo> [$coefficient], @results

Computes the ratings after a competition with an arbitrary number of
players.

The first argument is the coefficient. It is optional, with the
default coefficient being 15. The next arguments are the results of
the players. Each result is a 2-element arrayref, the first element
being the Elo rating of the player, and the second element being the
score that player obtained. The scores are only used to compare
players, their absolute values are irrelevant.

The return value is a list (in list context) or arrayref (in scalar
context) of ratings of all players after the competition, in the same
order as the arguments.

This function computes the ratings by considering that each player
played a game with every other player, with the winner of every game
being the player who got the highest score.

=back


=head1 SEE ALSO

L<Games::Ratings::Chess::FIDE>, L<Games::Ratings>

L<https://en.wikipedia.org/wiki/Elo_rating>

=head1 AUTHOR

Marius Gavrilescu <marius@ieval.ro>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
