#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Bot;
use Game::Dominoes::Terminal;

plan tests => 10;

sub text { $_[0]->game->to_text(with_seed => 1) }

sub plays { scalar grep { $_->{kind} eq 'play' } @{ $_[0]->game->history } }

sub bots {
	my (@seats) = @_;
	return { map { $_ => Game::Dominoes::Bot->new(level => 2, seed => $_ * 7919) } @seats };
}

sub driven {
	my (%args) = @_;
	my $input = $args{input} // '';
	my $output = '';
	open my $in, '<', \$input or die $!;
	open my $out, '>', \$output or die $!;

	my $term;
	my $driver = $args{driver};
	$term = Game::Dominoes::Terminal->new(
		game      => $args{game},
		bots      => $args{bots} || {},
		in        => $in,
		out       => $out,
		colour    => 0,
		ascii     => 1,
		width     => 200,
		handover  => 0,
		picking   => (exists $args{picking} ? $args{picking} : 1),
		keysource => sub { $driver ? $driver->($term) : undef },
	);
	return ($term, \$output);
}

sub scripted {
	my (@steps) = @_;
	return sub {
		my ($term) = @_;
		my $step = shift @steps;
		return undef unless $step;
		return ref $step ? $step->($term) : $step;
	};
}

sub person_drew {
	my ($term, $from) = @_;
	my $events = $term->game->history;
	return grep { $_->{kind} eq 'draw' && !$term->bots->{ $_->{seat} } }
		@{$events}[ $from .. $#$events ];
}

sub leading {
	my (%args) = @_;
	for my $letter ('a' .. 'z') {
		my $game = Game::Dominoes->new(seed => $letter x 32, %args);
		return $game if $game->turn == 1;
	}
	die 'no seed puts seat 1 first';
}

subtest 'u takes back your move and the reply, r plays them again' => sub {
	plan tests => 7;
	my %seen;
	my ($term, $out) = driven(
		game => leading(),
		bots => bots(2),
		driver => scripted(
			sub { $seen{first} = text($_[0]); "\r" },
			sub { $seen{second} = text($_[0]); $seen{plays} = plays($_[0]); 'u' },
			sub { $seen{back} = text($_[0]); $seen{back_plays} = plays($_[0]); 'r' },
			sub { $seen{again} = text($_[0]); 'q' },
		),
	);
	$term->start;

	is $seen{plays}, 2, 'your move and the reply were on the table';
	is $seen{back}, $seen{first}, 'u: the game is the one at your earlier turn';
	is $seen{back_plays}, 0, 'and the reply is gone with your move';
	is $seen{again}, $seen{second}, 'r: the game is back where it was';
	is scalar @{ $term->recent }, 2, 'the last-move marks came back with the plays';
	like ${$out}, qr/Taken back\./, 'u said so';
	like ${$out}, qr/Played again\./, 'r said so';
};

subtest 'a new move after u leaves nothing to play again' => sub {
	plan tests => 3;
	my %seen;
	my ($term, $out) = driven(
		game => leading(),
		bots => bots(2),
		driver => scripted(
			"\r",
			'u',
			sub { $seen{redo_after_u} = $_[0]->history->can_redo; "\e" },
			'[', 'B', "\r",
			sub { $seen{redo_after_move} = $_[0]->history->can_redo; $seen{text} = text($_[0]); 'r' },
			sub { $seen{after_r} = text($_[0]); 'q' },
		),
	);
	$term->start;

	ok $seen{redo_after_u}, 'after u there was something to play again';
	ok !$seen{redo_after_move}, 'a move threw it away';
	is $seen{after_r}, $seen{text}, 'and r changed nothing';
};

subtest 'u at the start says so and changes nothing' => sub {
	plan tests => 3;
	my %seen;
	my ($term, $out) = driven(
		game => leading(),
		bots => bots(2),
		driver => scripted(
			sub { $seen{before} = text($_[0]); 'u' },
			sub { $seen{after} = text($_[0]); 'r' },
			'q',
		),
	);
	$term->start;

	is $seen{after}, $seen{before}, 'the game is unchanged';
	like ${$out}, qr/There is nothing to take back\./, 'u said there was nothing';
	like ${$out}, qr/There is nothing to play again\./, 'r said there was nothing';
};

subtest 'hotseat: every move is a step' => sub {
	plan tests => 3;
	my %seen;
	my ($term) = driven(
		game => leading(),
		driver => scripted(
			"\r",
			sub { $seen{one} = text($_[0]); "\r" },
			sub { $seen{two} = text($_[0]); 'u' },
			sub { $seen{back} = text($_[0]); $seen{seat} = $_[0]->game->turn; 'u' },
			sub { $seen{start} = plays($_[0]); 'q' },
		),
	);
	$term->start;

	is $seen{back}, $seen{one}, 'one u took back one move';
	is $seen{seat}, 2, 'and it is the second seat to play again';
	is $seen{start}, 0, 'a second u took back the first';
};

subtest 'typed undo and redo' => sub {
	plan tests => 4;
	my $game = leading();
	my $before = $game->to_text(with_seed => 1);

	my ($played) = driven(game => leading(), bots => bots(2), picking => 0,
		input => "1\nquit\n");
	$played->start;

	my ($back, $out) = driven(game => $game, bots => bots(2), picking => 0,
		input => "1\nundo\nquit\n");
	$back->start;
	is text($back), $before, 'undo took back the move and the reply';
	like ${$out}, qr/Taken back\./, 'and said so';

	my ($again) = driven(game => leading(), bots => bots(2), picking => 0,
		input => "1\nundo\nredo\nquit\n");
	$again->start;
	is text($again), text($played), 'redo played them again';

	my ($word, $said) = driven(game => leading(), bots => bots(2), picking => 0,
		input => "u\nr\nquit\n");
	$word->start;
	like ${$said}, qr/I do not know 'u'.*I do not know 'r'/s,
		'a lone u or r typed is neither a move nor a command';
};

subtest 'three bots between your turns are taken back by one u' => sub {
	plan tests => 3;
	my %seen;
	my ($term) = driven(
		game => leading(players => 4, variant => 'block'),
		bots => bots(2, 3, 4),
		driver => scripted(
			sub { $seen{first} = text($_[0]); "\r" },
			sub { $seen{plays} = plays($_[0]); 'u' },
			sub { $seen{back} = text($_[0]); 'q' },
		),
	);
	$term->start;

	cmp_ok $seen{plays}, '>=', 2, 'the bots replied';
	is $seen{back}, $seen{first}, 'one u took back your move and every reply';
	is scalar @{ $term->recent }, 0, 'no marks are left for plays that are gone';
};

subtest 'your draw from the boneyard clears what can be taken back' => sub {
	plan tests => 4;
	my %seen;
	my $from = 0;
	my $driver = sub {
		my ($term) = @_;
		if (exists $seen{text}) {
			return undef if $seen{done}++;
			$seen{after} = text($term);
			return 'q';
		}
		if (person_drew($term, $from)) {
			$seen{text} = text($term);
			$seen{undo} = $term->history->can_undo;
			return 'u';
		}
		$from = scalar @{ $term->game->history };
		return "\r";
	};
	my ($term, $out) = driven(game => leading(), bots => bots(2), driver => $driver);
	$term->start;

	ok exists $seen{text}, 'you drew from the boneyard';
	ok !$seen{undo}, 'after it there was nothing to take back';
	is $seen{after}, $seen{text}, 'and u changed nothing';
	like ${$out}, qr/Drawing from the boneyard: nothing before it can be taken back\./,
		'the note said why';
};

subtest 'a bot drawing does not clear it' => sub {
	plan tests => 2;
	my %seen;
	my $from = 0;
	my $driver = sub {
		my ($term) = @_;
		my $events = $term->game->history;
		my @new = @{$events}[ $from .. $#$events ];
		$from = scalar @$events;
		return 'q' if grep { $_->{kind} eq 'hand_end' } @new;
		return 'q' if grep { $_->{kind} eq 'draw' && $_->{seat} == 1 } @new;
		if (!$seen{count} && grep { $_->{kind} eq 'draw' && $_->{seat} == 2 } @new) {
			$seen{count} = $term->history->undo_count;
			$seen{mine} = grep { $_->{kind} eq 'play' && $_->{seat} == 1 } @$events;
			return 'q';
		}
		return "\r";
	};
	my $found;
	for my $letter ('a' .. 'z') {
		my $game = Game::Dominoes->new(seed => $letter x 32);
		next unless $game->turn == 1;
		%seen = ();
		$from = 0;
		my ($term) = driven(game => $game, bots => bots(2), driver => $driver);
		$term->start;
		next unless $seen{count};
		$found = 1;
		last;
	}

	ok $found, 'a seed has the bot draw before you do';
	is $seen{count}, $seen{mine}, 'every move you made is still a step';
};

subtest 'a new hand clears what can be taken back' => sub {
	plan tests => 3;
	my %seen;
	my $driver = sub {
		my ($term) = @_;
		if (exists $seen{text}) {
			return undef if $seen{done}++;
			$seen{after} = text($term);
			return 'q';
		}
		if ($term->game->hand_number > 1) {
			$seen{text} = text($term);
			$seen{undo} = $term->history->can_undo;
			return 'u';
		}
		return "\r";
	};
	my ($term) = driven(game => leading(target => 500), bots => bots(2), driver => $driver);
	$term->start;

	ok exists $seen{text}, 'a second hand was dealt';
	ok !$seen{undo}, 'nothing in the hand before can be taken back';
	is $seen{after}, $seen{text}, 'and u changed nothing';
};

subtest 'bot against bot: nothing is kept' => sub {
	plan tests => 2;
	my $game = Game::Dominoes->new(seed => 'b' x 32, target => 50);
	my ($term) = driven(game => $game, bots => bots(1, 2));
	$term->start;
	is $game->status, 'finished', 'the bots played it out';
	ok !$term->history->can_undo, 'with nobody at the keys there is no step to take';
};
