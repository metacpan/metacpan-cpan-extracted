#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi;
use Game::Reversi::Terminal;

sub picked {
	my ($keys, %o) = @_;
	open my $in, '<', \(my $script = "quit\n") or die $!;
	my $text = '';
	open my $out, '>', \$text or die $!;
	my @chars = split //, $keys;
	my @seen;
	my $t;
	$t = Game::Reversi::Terminal->new(
		in => $in, out => $out, variant => 'othello', seed => 'history',
		level => 1, ascii => 1, ansi => 0, picking => 1,
		keysource => sub {
			return undef unless @chars;
			my $char = shift @chars;
			push @seen, { key => $char, text => $t->game->to_text,
				redo => $t->history->can_redo };
			return $char;
		},
		%o,
	);
	my $result = $t->start;
	close $out;
	return ($t, \@seen, \$text, $result);
}

{
	package Lines;
	sub TIEHANDLE {
		my ($class, $terminal, @lines) = @_;
		return bless { t => $terminal, lines => \@lines, seen => [] }, $class;
	}
	sub READLINE {
		my ($self) = @_;
		my $line = shift @{ $self->{lines} };
		return undef unless defined $line;
		push @{ $self->{seen} }, { line => $line, text => ${ $self->{t} }->game->to_text };
		return "$line\n";
	}
}

subtest 'u takes the turn and the bot reply back, r plays them again' => sub {
	my ($t, $seen) = picked("\rurq");

	my ($first, $second, $after_u, $after_r) = @$seen;
	isnt($second->{text}, $first->{text}, 'the second turn is a different position');
	is($after_u->{text}, $first->{text}, 'u went back to the first turn exactly');

	my $back = Game::Reversi->from_text($after_u->{text});
	is($back->turn, 'b', 'with dark to move');
	is_deeply($back->counts, { b => 2, w => 2 }, 'and the bot reply gone with the move');

	ok($after_u->{redo}, 'there was something to redo');
	is($after_r->{text}, $second->{text}, 'r played them again');
	done_testing();
};

subtest 'a move after u empties redo' => sub {
	my ($t, $seen) = picked("\ru" . "\e[C\r" . "r" . "q");

	my ($first, $undone) = @$seen[0, 2];
	my ($tried, $last) = grep { $_->{key} eq 'r' || $_->{key} eq 'q' } @$seen;
	is($undone->{text}, $first->{text}, 'u went back');
	ok($undone->{redo}, 'with something to redo');
	ok(!$tried->{redo}, 'after a new move there is nothing to redo');
	isnt($tried->{text}, $first->{text}, 'the new move was played');
	is($last->{text}, $tried->{text}, 'and r changed nothing');
	done_testing();
};

subtest 'u at the start notes it and changes nothing' => sub {
	my ($t, $seen, $text) = picked('uq');
	is($seen->[1]{text}, $seen->[0]{text}, 'the game did not move');
	like($$text, qr/nothing to take back/, 'and the note says why');
	done_testing();
};

subtest 'u on the first turn after the bot opened changes nothing' => sub {
	my ($t, $seen, $text) = picked('uq', colour => 'w');
	my $start = Game::Reversi->from_text($seen->[0]{text});
	is($start->turn, 'w', 'the bot had moved first');
	is_deeply($start->counts, { b => 4, w => 1 }, 'and its disc is down');
	is($seen->[1]{text}, $seen->[0]{text}, 'u left it there');
	like($$text, qr/nothing to take back/, 'and said so');
	done_testing();
};

subtest 'undo and redo typed' => sub {
	my $text = '';
	open my $out, '>', \$text or die $!;
	my $t;
	my $tie = tie *LINES, 'Lines', \$t, qw/d3 undo redo redo quit/;
	$t = Game::Reversi::Terminal->new(
		in => \*LINES, out => $out, variant => 'othello', seed => 'history',
		level => 1, ascii => 1, ansi => 0, picking => 0);
	$t->start;
	my @seen = @{ $tie->{seen} };
	undef $tie;
	untie *LINES;

	my ($d3, $undo, $redo, $again, $quit) = @seen;
	is($redo->{text}, $d3->{text}, 'undo went back to before d3');
	isnt($undo->{text}, $d3->{text}, 'from the turn after it');
	is($again->{text}, $undo->{text}, 'redo played it again');
	is($quit->{text}, $again->{text}, 'a second redo changed nothing');
	like($text, qr/nothing to redo/, 'and said so');
	done_testing();
};

subtest 'a game given to the terminal is the one played' => sub {
	my $game = Game::Reversi->new(variant => 'othello', seed => 'given');
	$game->play('b', $game->legal('b')->[0]->square);
	$game->play('w', $game->legal('w')->[0]->square);
	my $given = $game->to_text;
	my ($t, $seen, $text) = picked('uq', game => $game);
	is($t->game, $game, 'start kept it');
	is($seen->[0]{text}, $given, 'and the first turn is its position');
	like($$text, qr/nothing to take back/, 'which is where its history starts');
	done_testing();
};

done_testing();
