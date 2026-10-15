#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Terminal;

sub picked {
	my ($keys, %o) = @_;
	open my $in, '<', \(my $script = '') or die $!;
	my $text = '';
	open my $out, '>', \$text or die $!;
	my @chars = split //, $keys;
	my @seen;
	my $t;
	$t = Game::Go::Terminal->new(
		in => $in, out => $out, size => 9, level => 1, seed => 'history',
		ascii => 1, ansi => 0, picking => 1,
		keysource => sub {
			return undef unless @chars;
			my $char = shift @chars;
			push @seen, { key => $char, text => $t->game->to_text,
				redo => $t->history->can_redo };
			return $char;
		},
		%o,
	);
	$t->start;
	close $out;
	return ($t, \@seen, \$text);
}

sub typed {
	my ($script, %o) = @_;
	open my $in, '<', \$script or die $!;
	my $text = '';
	open my $out, '>', \$text or die $!;
	my $t = Game::Go::Terminal->new(
		in => $in, out => $out, size => 9, level => 1, seed => 'history',
		ascii => 1, ansi => 0, picking => 0,
		%o,
	);
	$t->start;
	close $out;
	return ($t, \$text);
}

sub plays {
	my ($text) = @_;
	return scalar grep { $_->{kind} eq 'play' } @{ Game::Go->from_text($text)->log };
}

subtest 'u takes the turn and the bot reply back, r plays them again' => sub {
	my ($t, $seen) = picked("\rurq");

	my ($first, $second, $after_u, $after_r) = @$seen;
	is(plays($second->{text}), 2, 'the second turn follows a move and the bot reply');
	is($after_u->{text}, $first->{text}, 'u went back to the first turn exactly');
	is(plays($after_u->{text}), 0, 'and the bot reply went with the move');
	ok($after_u->{redo}, 'there was something to redo');
	is($after_r->{text}, $second->{text}, 'r played them again');
	ok(!$after_r->{redo}, 'and then there was nothing more to redo');
	done_testing();
};

subtest 'r no longer resigns' => sub {
	my ($t, $seen, $text) = picked("\rrq");
	is($t->game->status, 'active', 'the game is still being played');
	like($$text, qr/there is nothing to play again/, 'r with nothing to redo says so');
	is($seen->[2]{text}, $seen->[1]{text}, 'and changes nothing');
	done_testing();
};

subtest 'a move after u empties redo' => sub {
	my ($t, $seen, $text) = picked("\ru" . "\e[C\r" . 'rq');

	my ($first, $undone) = @$seen[0, 2];
	my ($tried, $last) = grep { $_->{key} eq 'r' || $_->{key} eq 'q' } @$seen;
	is($undone->{text}, $first->{text}, 'u went back');
	ok($undone->{redo}, 'with something to redo');
	ok(!$tried->{redo}, 'after a new move there is nothing to redo');
	is(plays($tried->{text}), 2, 'the new move and its reply were played');
	is($last->{text}, $tried->{text}, 'and r changed nothing');
	like($$text, qr/there is nothing to play again/, 'but said so');
	done_testing();
};

subtest 'u at the start notes it and changes nothing' => sub {
	my ($t, $seen, $text) = picked('uq');
	is($seen->[1]{text}, $seen->[0]{text}, 'the game is unchanged');
	like($$text, qr/there is nothing to take back/, 'and it says so');
	done_testing();
};

subtest 'as white, the bot opening is not a step' => sub {
	my ($t, $seen, $text) = picked('uq', colour => 'white');
	is(plays($seen->[0]{text}), 1, 'the bot opened');
	is($seen->[1]{text}, $seen->[0]{text}, 'u did not take the opening back');
	like($$text, qr/there is nothing to take back/, 'and said so');
	done_testing();
};

subtest 'typed undo and redo' => sub {
	my ($one)  = typed("D4\n");
	my ($two)  = typed("D4\nF6\n");
	my ($back, $btext) = typed("D4\nF6\nundo\n");
	is($back->game->to_text, $one->game->to_text, 'undo went back a turn');

	my ($again) = typed("D4\nF6\nundo\nredo\n");
	is($again->game->to_text, $two->game->to_text, 'redo played it again');

	my ($none, $ntext) = typed("undo\nredo\n");
	like($$ntext, qr/There is nothing to take back/, 'undo at the start says so');
	like($$ntext, qr/There is nothing to play again/, 'and so does redo');
	is(plays($none->game->to_text), 0, 'and nothing changed');

	my ($h, $htext) = typed("help\n");
	like($$htext, qr/undo\s+take your last turn back/, 'help names undo');
	like($$htext, qr/redo\s+play a turn taken back again/, 'and redo');
	done_testing();
};

subtest 'undo in the marking phase goes back to the last turn of play' => sub {
	my ($stopped) = typed("pass\n" x 200);
	my $passes = grep { $_->{actor} eq 'b' && $_->{kind} eq 'pass' } @{ $stopped->game->log };
	is($stopped->game->phase, 'marking', 'passing stops play');

	my ($before) = typed("pass\n" x ($passes - 1));
	is($before->game->phase, 'play', 'one pass fewer is still play');

	my ($back, $text) = typed(("pass\n" x $passes) . "undo\n");
	is($back->game->phase, 'play', 'undo at the count leaves marking');
	is($back->game->to_text, $before->game->to_text, 'at the turn of the last pass');

	my ($again, $atext) = typed(("pass\n" x $passes) . "undo\npass\n");
	is($again->game->phase, 'marking', 'passing again stops play again');
	my $told = () = $$atext =~ /play has STOPPED/g;
	is($told, 2, 'and the marking phase is explained again');
	done_testing();
};

subtest 'the picker shows the keys that apply' => sub {
	my ($t, $seen, $text) = picked("\ruq");
	my @frames = split /arrows to move/, $$text;
	unlike($frames[1], qr/u undo/, 'no undo before the first turn is played');
	like($$text, qr/p pass, u undo, \? for the keys/, 'u undo once there is a turn');
	like($$text, qr/p pass, r redo, \? for the keys/, 'r redo after u');
	my (undef, undef, $htext) = picked('?q');
	like($$htext, qr/u takes your last turn back, r plays it again/, '? names u and r');
	like($$htext, qr/where resign gives up/, 'and how to resign now');
	done_testing();
};

done_testing();
