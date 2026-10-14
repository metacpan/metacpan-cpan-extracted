#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::History;

{
	package Moves;
	sub new { my ($class, @moves) = @_; return bless { moves => [@moves] }, $class }
	sub play { my ($self, $move) = @_; push @{ $self->{moves} }, $move; return $self }
	sub text { my ($self) = @_; return join ' ', @{ $self->{moves} } }
}

my ($saved, $loaded) = (0, 0);

sub history {
	my (%option) = @_;
	($saved, $loaded) = (0, 0);
	return Game::Terminal::Kit::History->new(
		save => sub { $saved++; return $_[0]->text },
		load => sub { $loaded++; return Moves->new(split / /, $_[0]) },
		%option,
	);
}

sub moves { my ($game) = @_; return defined $game ? $game->text : undef }

subtest 'a new game has nothing to take back' => sub {
	plan tests => 9;
	my $history = history();
	is $history->start(Moves->new), $history, 'start returns the history';
	is $history->undo, undef, 'nothing to undo';
	is $history->redo, undef, 'nor to redo';
	ok !$history->can_undo, 'can_undo is false';
	ok !$history->can_redo, 'can_redo is false';
	is $history->undo_count, 0, 'no steps back';
	is $history->redo_count, 0, 'and none forward';
	is $history->legend, '', 'so the legend is empty';
	is $loaded, 0, 'and no game was built';
};

subtest 'back three turns and forward again' => sub {
	plan tests => 13;
	my $history = history();
	my $game = Moves->new;
	$history->start($game);
	is $history->record($game->play('e3')), $history, 'record returns the history';
	$history->record($game->play('f4'));
	$history->record($game->play('g5'));
	is $history->undo_count, 3, 'three steps';
	is $history->text, 'e3 f4 g5', 'the current version is the last one recorded';

	is moves($history->undo), 'e3 f4', 'one back';
	is moves($history->undo), 'e3', 'two back';
	is moves($history->undo), '', 'back to the start';
	is $history->undo, undef, 'and no further';
	is $history->redo_count, 3, 'three to redo';

	is moves($history->redo), 'e3', 'one forward';
	is moves($history->redo), 'e3 f4', 'two forward';
	is moves($history->redo), 'e3 f4 g5', 'back where it was';
	is $history->redo, undef, 'and no further';
	is $loaded, 6, 'one game built for each step taken';
};

subtest 'several steps at once' => sub {
	plan tests => 8;
	my $history = history();
	my $game = Moves->new;
	$history->start($game);
	$history->record($game->play($_)) for qw/a b c d e/;
	$loaded = 0;
	is moves($history->undo(3)), 'a b', 'three back at once';
	is $loaded, 1, 'building one game, not three';
	is moves($history->undo(10)), '', 'more than there are goes back to the start';
	is moves($history->redo(2)), 'a b', 'two forward at once';
	is $history->undo_count, 2, 'two to undo now';
	is $history->redo_count, 3, 'and three to redo';
	is moves($history->undo(0)), undef, 'no steps is no game';
	is $history->undo_count, 2, 'and nothing moved';
};

subtest 'what is a step and what is not' => sub {
	plan tests => 7;
	my $history = history();
	my $game = Moves->new('a');
	$history->start($game);
	$history->record($game);
	is $history->undo_count, 0, 'recording a game nobody moved is no step';
	$history->record($game->play('b'));
	$history->record($game);
	is $history->undo_count, 1, 'nor is recording it twice';

	$history->record($game->play('c'));
	my $earlier = $history->undo;
	is $history->redo_count, 1, 'an undo can be redone';
	$history->record($earlier->play('x'));
	is $history->redo_count, 0, 'until a new move is recorded';
	is $history->text, 'a b x', 'which is the current version';

	$history->start(Moves->new('z'));
	is $history->undo_count + $history->redo_count, 0, 'start forgets both ways';
	is $history->text, 'z', 'and holds the new game';
};

subtest 'the kept game never changes' => sub {
	plan tests => 2;
	my $history = history();
	my $game = Moves->new;
	$history->start($game);
	$history->record($game->play('a'));
	my $earlier = $history->undo;
	$earlier->play('changed after the undo');
	is moves($history->redo), 'a', 'a game handed out and then played does not change what was kept';
	is moves($history->undo), '', 'either way';
};

subtest 'a limit' => sub {
	plan tests => 5;
	my $history = history(limit => 2);
	my $game = Moves->new;
	$history->start($game);
	$history->record($game->play($_)) for qw/a b c d/;
	is $history->undo_count, 2, 'two kept';
	is moves($history->undo(5)), 'a b', 'the oldest forgotten';
	is history()->limit, 200, 'two hundred by default';

	my $all = history(limit => 0);
	$all->start(Moves->new);
	$all->record(Moves->new(1 .. $_)) for 1 .. 300;
	is $all->undo_count, 300, 'a limit of 0 keeps every step';
	is $all->store->history_limit, undef, 'which is no limit on the store';
};

subtest 'clear' => sub {
	plan tests => 3;
	my $history = history();
	my $game = Moves->new;
	$history->start($game);
	$history->record($game->play('a'));
	$history->record($game->play('b'));
	$history->undo;
	is $history->clear, $history, 'clear returns the history';
	is $history->undo_count + $history->redo_count, 0, 'and forgets both ways';
	is $history->text, 'a', 'keeping the current version';
};

subtest 'the keys and the legend' => sub {
	plan tests => 4;
	my $history = history();
	is_deeply $history->game_keys, { u => 'undo', r => 'redo' }, 'u and r';
	my $game = Moves->new;
	$history->start($game);
	$history->record($game->play('a'));
	is $history->legend, 'u undo', 'u once there is a step';
	$history->record($game->play('b'));
	$history->undo;
	is $history->legend, 'u undo, r redo', 'both in the middle';
	$history->undo;
	is $history->legend, 'r redo', 'r alone at the start';
};

subtest 'what save must give back' => sub {
	plan tests => 6;
	my $bad = Game::Terminal::Kit::History->new(save => sub { [] }, load => sub { });
	ok !eval { $bad->start(Moves->new); 1 }, 'a reference is refused';
	like $@, qr/^Game::Terminal::Kit::History: save gave a reference for Moves, where a string is needed/, 'naming the game';
	my $none = Game::Terminal::Kit::History->new(save => sub { undef }, load => sub { });
	ok !eval { $none->record(Moves->new); 1 }, 'nothing is refused';
	like $@, qr/save gave nothing for Moves/, 'saying so';
	ok !eval { Game::Terminal::Kit::History->new(save => sub { '' }); 1 }, 'load is needed';
	like $@, qr/save and load are both needed/, 'and saying so';
};

subtest 'a turn: the first one begins, the rest are steps' => sub {
	plan tests => 7;
	my $history = history();
	my $game = Moves->new;
	$history->start($game);
	ok !$history->begun, 'not begun after start';
	$game->play('bot');
	is $history->turn($game), $history, 'turn returns the history';
	ok $history->begun, 'begun after the first turn';
	is $history->undo_count, 0, 'a move made before the first turn is not a step';
	$history->turn($game->play('me')->play('bot'));
	is moves($history->undo), 'bot', 'a later turn is a step, back to where the person began';
	$history->start(Moves->new);
	ok !$history->begun, 'start begins again';
	$history->turn(Moves->new('x'));
	is $history->undo_count, 0, 'and the next turn is a beginning again';
};

subtest 'a load that gives back nothing' => sub {
	plan tests => 3;
	my $history = Game::Terminal::Kit::History->new(save => sub { $_[0]->text }, load => sub { return });
	my $game = Moves->new;
	$history->start($game);
	$history->record($game->play('a'));
	ok !eval { $history->undo; 1 }, 'is an error, not an empty history';
	like $@, qr/load gave nothing back/, 'saying so';
	is $history->undo_count, 0, 'the step was taken in the store before load was asked';
};

done_testing;
