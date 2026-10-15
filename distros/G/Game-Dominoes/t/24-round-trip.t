#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Bot;

plan tests => 10;

sub save { return $_[0]->to_text(with_seed => 1) }
sub load { return Game::Dominoes->from_text($_[0]) }

sub bot { return Game::Dominoes::Bot->new(level => 3, seed => 5) }

sub legal_text {
	my ($g) = @_;
	return '' unless defined $g->turn;
	return join ' ', sort map { $_->{tile}->stringify . '@' . $_->{arm} } @{ $g->legal($g->turn) };
}

sub secret {
	my ($g) = @_;
	return join ' / ',
		(map { "$_:" . join(',', map { $_->stringify } @{ $g->hand($_)->tiles }) } $g->seats),
		join(',', map { $_->stringify } @{ $g->boneyard->tiles }),
		join(',', map { "$_:" . $g->scores->{$_} } $g->seats),
		$g->hand_number, $g->leader, $g->turn // '-', $g->status, $g->passes,
		($g->forced_tile ? $g->forced_tile->stringify : '-');
}

sub step {
	my ($g, $bot) = @_;
	my $move = $bot->choose($g, $g->turn) or return undef;
	my $play = $g->play($g->turn, $move);
	return $play->tile->stringify . '@' . $play->arm;
}

sub next_three {
	my ($g) = @_;
	my $bot = bot();
	my @out;
	for (1 .. 3) {
		last unless $g->status eq 'active';
		push @out, step($g, $bot);
	}
	return join ' ', map { $_ // '-' } @out;
}

sub round_trip {
	my ($g, $name) = @_;
	subtest $name => sub {
		plan tests => 6;
		my $text = save($g);
		my $back = load($text);

		is save($back), $text, 'save(load(save)) is save';
		is secret($back), secret($g), 'the hands, the boneyard, the scores and the turn come back';
		is legal_text($back), legal_text($g), 'the same legal moves';

		my $before = save($g);
		my $mine = next_three(load($text));
		my $theirs = next_three($back);
		is $theirs, $mine, 'the bot plays the same next three moves';
		is save($g), $before, 'playing on the rebuilt game leaves the original alone';

		my $copy = load($text);
		next_three($g) if $g->status eq 'active';
		is save($copy), $text, 'and playing on the original leaves the rebuilt one alone';
	};
}

sub fresh { return Game::Dominoes->new(seed => 'a' x 32, @_) }

round_trip(fresh(), 'at the start');

{
	my $g = fresh();
	my $bot = bot();
	step($g, $bot) for 1 .. 3;
	round_trip($g, 'after three plays');
}

{
	my $g = fresh(players => 3);
	my $bot = bot();
	my $n = 0;
	while ($g->status eq 'active' && $n++ < 500) {
		step($g, $bot);
		last if $g->history->[-1]{kind} eq 'draw' && $g->forced_tile;
	}
	ok $g->forced_tile, 'a seat has drawn from the boneyard onto a forced tile';
	round_trip($g, 'after a draw from the boneyard');
}

{
	my $g = fresh();
	my $bot = bot();
	my $n = 0;
	while ($g->status eq 'active' && $g->hand_number < 2 && $n++ < 500) {
		step($g, $bot);
	}
	is $g->hand_number, 2, 'the first hand is scored and the second dealt';
	round_trip($g, 'after a hand is scored and the next dealt');
}

my $ended = fresh(players => 4, reserve => 2);
{
	my $bot = bot();
	my $n = 0;
	step($ended, $bot) while $ended->status eq 'active' && $n++ < 5000;
	round_trip($ended, 'at the end of a game the bot played out');
}

{
	my $g = fresh(players => 2, target => 61, scale => 5);
	my $bot = bot();
	step($g, $bot) for 1 .. 4;
	$g->resign(2);
	round_trip($g, 'after a resignation');
}

subtest 'the log without the seed, given the seed' => sub {
	plan tests => 2;
	my $back = Game::Dominoes->from_text($ended->to_text, seed => 'a' x 32, players => 4, reserve => 2);
	is save($back), save($ended), 'the one line of moves and the settings rebuild the game';
	ok !eval { Game::Dominoes->from_text($ended->to_text); 1 }, 'and without a seed it is refused';
};

subtest 'malformed text is refused with a sentence' => sub {
	my $good = save($ended);
	my @bad = (
		[ undef, qr/wants the text of a game/ ],
		[ "colour blue\n$good", qr/does not know the line/ ],
		[ ($good =~ s/^seed \S+/seed 12/r), qr/64 hexadecimal digits/ ],
		[ ($good =~ s/^players \d+/players four/mr), qr/players must be a whole number/ ],
		[ ($good =~ s/^moves .*//mr), qr/no moves line/ ],
		[ ($good =~ s/^moves (\S+)/moves Z$1/mr), qr/could not read the moves/ ],
		[ ($good =~ s/^moves (\S+) (\S+)/moves $1 $1 $2/mr), qr/move 2, .* was refused/ ],
		[ ($good =~ s/ \| / /r), qr/are not the ones its plays make/ ],
		[ "$good 6-6\@L", qr/after the game is over/ ],
		[ "players 2\n$good", qr/two players lines/ ],
	);
	plan tests => scalar @bad;
	for my $case (@bad) {
		my ($text, $want) = @$case;
		ok !eval { Game::Dominoes->from_text($text); 1 } && $@ =~ $want,
			'refused: ' . ($@ =~ s/ at \S+ line \d+.*//sr);
	}
};
