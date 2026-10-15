use strict;
use warnings;
use Test::More;

use Digest::SHA ();
use Game::Backgammon;
use Game::Backgammon::Bot;

my $G = 'Game::Backgammon';

sub seed_of { Digest::SHA::sha256($_[0]) }

sub turns_of { join ' | ', map { $_->key } @{ $_[0]->legal_turns } }

sub bot_line {
	my ($game) = @_;
	my $bot = Game::Backgammon::Bot->new(level => 3);
	my @line;
	for (1 .. 3) {
		last if $game->result;
		my $turn = $bot->choose($game);
		push @line, $game->turn . ' ' . join('', @{ $game->dice }) . ' ' . $turn->notation;
		$game->play($turn) or die $@;
	}
	return join ' | ', @line, $game->to_text;
}

sub round_trip {
	my ($game, $name) = @_;
	subtest $name => sub {
		my $text = $game->to_text;
		ok(defined $text && !ref $text, 'the text is a string');
		my $again = $G->from_text($text);
		isnt($again, $game, 'a new game');
		is($again->to_text, $text, 'which writes the same text');
		is_deeply([ $again->board->points, $again->board->bar_counts, $again->board->off_counts ],
			[ $game->board->points, $game->board->bar_counts, $game->board->off_counts ], 'the same board');
		is($again->status, $game->status, 'the same status');
		is($again->turn, $game->turn, 'the same player to move');
		is($again->rolls, $game->rolls, 'the same count of rolls');
		is(join(',', @{ $again->dice }), join(',', @{ $game->dice }), 'the same dice waiting');
		is(turns_of($again), turns_of($game), 'the same legal turns');
		if ($game->result) {
			is($again->result->stringify, $game->result->stringify, 'the same result');
			return;
		}
		my ($one, $two) = ($G->from_text($text), $G->from_text($text));
		is(bot_line($two), bot_line($one), 'the next three bot turns, and the dice they fall to, are the same');
		my $mine = $G->from_text($text);
		my $before = $game->to_text;
		$mine->play($mine->legal_turns->[0]) or die $@;
		is($game->to_text, $before, 'playing on the copy leaves the original alone');
		my ($copy, $orig) = ($G->from_text($text), $G->from_text($text));
		my (@a, @b);
		for (1 .. 6) {
			last if $copy->result;
			$copy->play($copy->legal_turns->[-1]) or die $@;
			$orig->play($orig->legal_turns->[-1]) or die $@;
			push @a, join '', @{ $copy->dice };
			push @b, join '', @{ $orig->dice };
		}
		is("@a", "@b", 'the dice to come are the same');
	};
}

sub until_turn {
	my ($seed, $want) = @_;
	my $game = $G->new(seed => seed_of($seed));
	my $bot = Game::Backgammon::Bot->new(level => 1);
	until ($game->result) {
		my $turn = $bot->choose($game);
		$game->play($turn) or die $@;
		return $game if $want->($turn, $game);
	}
	return $game;
}

my $start = $G->new(seed => seed_of('round trip'));
round_trip($start, 'at the start, the opening dice thrown and not yet played');

my $unasked = $G->new(seed => seed_of('round trip'));
$unasked->play($unasked->legal_turns->[0]) or die $@;
my $asked = $G->new(seed => seed_of('round trip'));
$asked->play($asked->legal_turns->[0]) or die $@;
$asked->dice;
is($asked->to_text, $unasked->to_text, 'dice thrown and not yet played write the same text as dice not yet asked for');
round_trip($asked, 'after a turn, the next dice thrown and not yet played');

my $three = $G->new(seed => seed_of('round trip'));
$three->play($three->legal_turns->[0]) or die $@ for 1 .. 3;
round_trip($three, 'after three turns');

my $hit = until_turn('a hit', sub { grep { $_->hit } @{ $_[0]->moves } });
ok(!$hit->result && grep({ $_->hit } @{ $hit->history->[-1]->moves }), 'a hit was found');
round_trip($hit, 'after a hit, a checker on the bar');

my $doubles = until_turn('doubles', sub { $_[0]->is_doubles });
ok(!$doubles->result && $doubles->history->[-1]->is_doubles, 'doubles were found');
round_trip($doubles, 'after doubles');

my $forfeit;
for my $n (1 .. 40) {
	my $game = until_turn("forfeit $n", sub { $_[0]->is_forfeit });
	next if $game->result;
	$forfeit = $game;
	last;
}
ok($forfeit, 'a turn with no play was found');
like($forfeit->to_text, qr/: \(no play\)\n\z/, 'and written as one');
round_trip($forfeit, 'after a turn with no play');

my $late = $G->new(seed => seed_of('late'));
my $bot = Game::Backgammon::Bot->new(level => 3);
my @texts;
until ($late->result) {
	push @texts, $late->to_text;
	$late->play($bot->choose($late)) or die $@;
}
round_trip($G->from_text($texts[-3]), 'late in a game the bot played out');
round_trip($late, 'at the end of that game, borne off');
like($late->to_text, qr/^\[result (?:white|black) \w+ borne_off\]\n\z/m, 'the end is written');

my $resigned = $G->new(seed => seed_of('resign'));
$resigned->play($resigned->legal_turns->[0]) or die $@ for 1 .. 5;
$resigned->finish(winner => 'black');
round_trip($resigned, 'after a resignation');

my $timeout = $G->new(seed => seed_of('timeout'));
$timeout->play($timeout->legal_turns->[0]) or die $@ for 1 .. 2;
$timeout->finish(winner => 'white', margin => 'gammon', reason => 'timeout');
round_trip($timeout, 'after a finish from outside with a margin and a reason');

subtest 'a malformed text is refused with a sentence' => sub {
	my $text = $three->to_text;
	my ($first) = $text =~ /^1\. (\w+)/m;
	my $other = $first eq 'white' ? 'black' : 'white';
	for my $case (
		[ undef,                                         qr/was given nothing/ ],
		[ {},                                            qr/was given a reference/ ],
		[ '',                                            qr/does not end with a newline/ ],
		[ "nonsense\n",                                  qr/line 1 is not the seed/ ],
		[ $text =~ s/\n\z//r,                            qr/does not end with a newline/ ],
		[ $text =~ s/^2\. /9. /mr,                       qr/line 3 is numbered 9 where 2 was next/ ],
		[ $text =~ s/^1\. $first/1. $other/mr,           qr/line 2 is $other to play where it is ${first}'s turn/ ],
		[ $text =~ s/^(1\. \w+ )(\d+)/$1 . ($2 eq '12' ? '21' : '12')/mer, qr/line 2 rolls \d+ where the seed rolls/ ],
		[ $text =~ s/^(1\. \w+ \d+: ).*$/${1}24\/1/mr,  qr/line 2 does not play: the rules do not offer that turn/ ],
		[ $text =~ s/^(1\. \w+ \d+: ).*$/${1}9\/x/mr,   qr/line 2 does not play: that is not backgammon notation/ ],
		[ $text =~ s/^2\. .*$/two/mr,                    qr/line 3 is not a turn/ ],
		[ "$text\[result white single resign]\n1. white 12: 8/7\n", qr/follows the result/ ],
		[ "$text\[result white single borne_off]\n",     qr/borne off, and they were not/ ],
		[ $late->to_text =~ s/\[result .*\]\n//r,        qr/the game ended but the text has no result/ ],
		[ $late->to_text =~ s/\[result (\w+) (\w+) borne_off\]/"[result $1 " . ($2 eq 'single' ? 'gammon' : 'single') . " borne_off]"/er, qr/the result is not the one the game ended with/ ],
	) {
		my ($bad, $like) = @$case;
		my $game = eval { $G->from_text($bad) };
		ok(!$game, 'refused');
		like($@, qr/\AGame::Backgammon: the text was refused: /, 'by the game');
		like($@, $like, 'saying why');
	}
};

done_testing;
