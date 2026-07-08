package Game::Cribbage::Score;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use ntheory qw/forcomb vecsum/;

has total_score => (
	is => 'rw',
	isa => Int
);

has scored => (
	is => 'ro',
	builder => 1
);

sub _build_scored { 
	return {
		fifteen => 2,
		pair => 2,
		three_of_a_kind => 6,
		four_of_a_kind => 12,
		run => [3, 4, 5],
		four_flush => 4,
		five_flush => 5,
		nobs => 1
	}
}

has [qw/fifteen pair three_of_a_kind four_of_a_kind run four_flush five_flush nobs cards/] => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

has with_starter => (
	is => 'ro',
	isa => Bool
);

sub BUILD {
	my ($self, $params) = @_;
	my $starter = $self->cards->[-1];
	my @cards = sort { $b->value <=> $a->value } @{$self->cards};
	$self->calculate_fifteen(@cards);
	$self->calculate_of_a_kind(@cards);
	$self->calculate_run(@cards);
	$self->calculate_flush(@cards);
	$self->calculate_nob($starter, @cards) if $self->with_starter;
	$self->calculate_total();
	return $self;
}

sub calculate_nob {
	my ($self, $starter, @cards) = @_;

	return if ($starter->symbol eq 'J');

	for (@cards) {
		if ($_->symbol eq 'J' && $starter->suit eq $_->suit) {
			push @{$self->nobs}, $_;
			last;
		}
	}
};

sub calculate_run {
	my ($self, @cards) = @_;

	my @values = map { $_->run_value } @cards;
	
	my %map;
	foreach my $n (1 .. @values) {
		forcomb {
			my $first = $values[$_[0]];
        		my $match = 1;
        		return if scalar @_ < 3;
        		for (my $i = 1; $i < scalar(@_); $i++) {
                		$first = $first - 1;
                		if ($first != $values[$_[$i]]) {
                        		$match = 0;
                		}
        		}
        		if ($match) {
                		if (scalar(@_) == 3) {
                       	 		push @{$map{three}}, [@cards[@_]];
                		} elsif (scalar(@_) == 4) {
                        		push @{$map{four}}, [@cards[@_]];
                		} else {
                        		push @{$map{five}}, [@cards[@_]];
                		}
        		}
		} @values, $n;
	}
	
	if ($map{five}) {
		$self->run($map{five});
	} elsif ($map{four}) {
		$self->run($map{four});
	} elsif ($map{three}) {
		$self->run($map{three});
	}
}

sub calculate_flush {
	my ($self, @cards) = @_;
	my %map;
	push @{$map{$_->suit}}, $_ for (@cards);
	for (keys %map) {
		my $c = scalar @{$map{$_}};
		if ($c == 4) {
			push @{$self->four_flush}, $map{$_};
		} elsif ($c == 5) {
			push @{$self->five_flush}, $map{$_};
		}
	}

}

sub calculate_fifteen {
	my ($self, @cards) = @_;
	my @values = map { $_->value } @cards;
	foreach my $n (1 .. @values) {
		forcomb {
			push @{$self->fifteen}, [@cards[@_]] if vecsum(@values[@_]) == 15;
		} @values, $n
	}
}

sub calculate_of_a_kind {
	my ($self, @cards) = @_;
	my %map = ();
	push @{$map{$_->symbol}}, $_ for (@cards);
	for (keys %map) {
		my $c = scalar @{$map{$_}};
		next if ($c == 1);
		if ($c == 2) {
			push @{$self->pair}, $map{$_};
		} elsif ($c == 3) {
			push @{$self->three_of_a_kind}, $map{$_};
		} elsif ($c == 4) {
			push @{$self->four_of_a_kind}, $map{$_};
		}
	}
}

sub calculate_total {
	my ($self) = @_;
	my $scored = $self->scored;
	my $score = 0;
	for (keys %{$scored}) {
		if (scalar @{$self->$_}) {
			if ($_ eq 'run') {
				$score += scalar @{$self->$_} * scalar @{$self->$_->[0]} 
					if $self->$_->[0];
			} else {
				$score += $scored->{$_} * scalar @{$self->$_};
			}
		}
	}
	$self->total_score($score);
}

1;

__END__

=head1 NAME

Game::Cribbage::Score - hand scoring calculator

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Score;

	# score a 4-card hand without the starter
	my $score = Game::Cribbage::Score->new(
		with_starter => 0,
		cards        => \@cards,
	);
	print $score->total_score;

	# score with the starter (5th card)
	my $score = Game::Cribbage::Score->new(
		with_starter => 1,
		cards        => [@hand_cards, $starter],
	);
	print $score->total_score;

=head1 DESCRIPTION

Calculates the cribbage hand score for a set of L<Game::Cribbage::Deck::Card>
objects by enumerating all scoring combinations: fifteens, pairs, three/four of
a kind, runs, flushes, and nobs.  Scoring is performed in C<BUILD> immediately
after construction; the result is available via C<total_score>.

=head1 PROPERTIES

=head2 total_score

Read/write integer property holding the computed total score. Set by
C<calculate_total> during construction.

	$score->total_score;

=head2 scored

Readonly hashref containing the point value for each scoring category.
Built automatically.

	$score->scored;
	# {
	#   fifteen        => 2,
	#   pair           => 2,
	#   three_of_a_kind => 6,
	#   four_of_a_kind  => 12,
	#   run            => [3, 4, 5],
	#   four_flush     => 4,
	#   five_flush     => 5,
	#   nobs           => 1,
	# }

=head2 fifteen

Read/write arrayref of card-group arrayrefs, each group summing to 15.

	$score->fifteen;

=head2 pair

Read/write arrayref of paired card groups.

	$score->pair;

=head2 three_of_a_kind

Read/write arrayref of three-of-a-kind card groups.

	$score->three_of_a_kind;

=head2 four_of_a_kind

Read/write arrayref of four-of-a-kind card groups.

	$score->four_of_a_kind;

=head2 run

Read/write arrayref of run card groups (runs of three, four, or five).

	$score->run;

=head2 four_flush

Read/write arrayref populated when exactly four cards share a suit.

	$score->four_flush;

=head2 five_flush

Read/write arrayref populated when all five cards (including starter) share
a suit.

	$score->five_flush;

=head2 nobs

Read/write arrayref populated when the hand contains a Jack whose suit
matches the starter card.

	$score->nobs;

=head2 cards

Read/write arrayref of L<Game::Cribbage::Deck::Card> objects to score.
The last element is treated as the starter when C<with_starter> is true.

	$score->cards;

=head2 with_starter

Readonly boolean indicating whether the last element of C<cards> is the
starter card.  When true, nobs scoring is applied.

	$score->with_starter;

=head1 FUNCTIONS

=head2 calculate_nob

Checks whether the hand contains a Jack matching the starter suit, and if so
pushes it onto C<nobs>.  Only called when C<with_starter> is true.

	$score->calculate_nob($starter, @cards);

=head2 calculate_run

Enumerates all card subsets to find runs of three, four, or five consecutive
run-values and stores them in C<run>.

	$score->calculate_run(@cards);

=head2 calculate_flush

Detects four-card or five-card flushes and populates C<four_flush> or
C<five_flush> accordingly.

	$score->calculate_flush(@cards);

=head2 calculate_fifteen

Finds all card subsets whose pip values sum to 15 and pushes them onto
C<fifteen>.

	$score->calculate_fifteen(@cards);

=head2 calculate_of_a_kind

Groups cards by symbol and populates C<pair>, C<three_of_a_kind>, or
C<four_of_a_kind> as appropriate.

	$score->calculate_of_a_kind(@cards);

=head2 calculate_total

Sums the contribution of every populated scoring category and stores the
result in C<total_score>.

	$score->calculate_total();

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-cribbage at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Cribbage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Cribbage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Cribbage>

=item * Search CPAN

L<https://metacpan.org/release/Game-Cribbage>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
