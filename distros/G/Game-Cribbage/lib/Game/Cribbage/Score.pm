package Game::Cribbage::Score;

use strict;
use warnings;

use Rope;
use Rope::Autoload;
use ntheory qw/forcomb vecsum/;

property total_score => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1
);

property scored => (
	initable => 1,
	writeable => 0,
	configurable => 0,
	enumerable => 1,
	value => {
		fifteen => 2,
		pair => 2,
		three_of_a_kind => 6,
		four_of_a_kind => 12,
		run => [3, 4, 5],
		four_flush => 4,
		five_flush => 5,
		nobs => 1
	}
);

property [qw/fifteen pair three_of_a_kind four_of_a_kind run four_flush five_flush nobs/] => (
	initable => 1,
	writeable => 0,
	configurable => 1,
	enumerable => 1,
	value => []
);

function INITIALISED => sub {
	my ($self, $params) = @_;
	my $starter = $params->{_cards}->[-1];
	my @cards = sort { $b->value <=> $a->value } @{$params->{_cards}};
	$self->calculate_fifteen(@cards);
	$self->calculate_of_a_kind(@cards);
	$self->calculate_run(@cards);
	$self->calculate_flush(@cards);
	$self->calculate_nob($starter, @cards) if $params->{_with_starter};
	$self->calculate_total();
	return $self;
};

function calculate_nob => sub {
	my ($self, $starter, @cards) = @_;

	return if ($starter->symbol eq 'J');

	for (@cards) {
		if ($_->symbol eq 'J' && $starter->suit eq $_->suit) {
			push @{$self->nobs}, $_;
			last;
		}
	}
};

function calculate_run => sub {
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
		$self->run = $map{five};
	} elsif ($map{four}) {
		$self->run = $map{four};
	} elsif ($map{three}) {
		$self->run = $map{three};
	}
};

function calculate_flush => sub {
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

};

function calculate_fifteen => sub {
	my ($self, @cards) = @_;
	my @values = map { $_->value } @cards;
	foreach my $n (1 .. @values) {
		forcomb {
			push @{$self->fifteen}, [@cards[@_]] if vecsum(@values[@_]) == 15;
		} @values, $n
	}
};

function calculate_of_a_kind => sub {
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
};

function calculate_total => sub {
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
	$self->total_score = $score;
};

1;
