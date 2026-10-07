#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;
use Game::Checkers::Terminal;

# every one of these runs without a terminal: the keys come from keysource, so
# nothing here needs a tty, a pipe, or Term::ReadKey to be installed
sub terminal {
	my ($keys, %option) = @_;
	my @chars = split //, defined $keys ? $keys : '';
	my $output = '';
	open my $out, '>', \$output or die "in memory handle: $!";
	my $terminal = Game::Checkers::Terminal->new(
		out => $out,
		interactive => 0,
		colour => 0,
		ascii => 1,
		keysource => sub { shift @chars },
		picking => 1,
		%option
	);
	return ($terminal, \$output, \@chars);
}

subtest 'a key at a time, named' => sub {
	plan tests => 2;
	my ($terminal) = terminal("k\e[A\e[B\e[C\e[D\e[5~\eOH\r\t\x7f\x03\x04 q\e\e[6~");
	my @got;
	while (defined(my $key = $terminal->read_key)) {
		push @got, $key eq ' ' ? 'space' : $key;
	}
	is_deeply \@got, [qw/k up down right left page_up home enter tab backspace
		interrupt eof space q escape page_down/],
		'a character comes back as itself and a sequence as a name';

	my ($named) = terminal("\e[A");
	ok length($named->read_key) > 1, 'so a name is the longer of the two';
};

subtest 'an escape does not eat the key behind it' => sub {
	plan tests => 2;
	# the escape key, pressed, then a real one: with nothing to tell them apart
	# but the next byte, the next byte has to be given back
	my ($terminal) = terminal("\eq");
	is $terminal->read_key, 'escape', 'the escape is an escape';
	is $terminal->read_key, 'q', 'and the keystroke behind it survives';
};

subtest 'the arrow keys choose a move' => sub {
	plan tests => 4;
	my ($terminal, $output) = terminal("\e[B\e[B\r", human => 'both');
	my $legal = $terminal->game->legal_moves;
	my $third = $legal->[2]->coord_notation;

	$terminal->enter_raw;
	my $line = $terminal->pick;
	is $line, '', 'a picked move is played there and then, not handed back';
	is $terminal->game->ply, 1, 'so a move was made';
	is $terminal->game->history->[-1]->coord_notation, $third,
		'the third one, two presses down from the first';
	like ${$output}, qr/up and down to choose/, 'and the keys were on the screen';
};

subtest 'the list is numbered and can be jumped into' => sub {
	plan tests => 2;
	my ($terminal) = terminal('5' . "\r", human => 'both');
	my $fifth = $terminal->game->legal_moves->[4]->coord_notation;
	$terminal->enter_raw;
	$terminal->pick;
	is $terminal->game->ply, 1, 'a digit and an enter is a move';
	is $terminal->game->history->[-1]->coord_notation, $fifth,
		'the one that digit numbers';
};

subtest 'what the picker hands back' => sub {
	plan tests => 3;
	my ($undo) = terminal('u', human => 'both');
	$undo->enter_raw;
	is $undo->pick, 'undo', 'a key that is a command comes back as the word';

	my ($typed) = terminal(":level 2\r", human => 'both');
	$typed->enter_raw;
	is $typed->pick, 'level 2', 'and a colon hands back the line that follows it';

	my ($gone) = terminal('', human => 'both');
	$gone->enter_raw;
	is $gone->pick, undef, 'the end of the input ends the game, it does not hang';
};

subtest 'the cursor is on the board as well as the list' => sub {
	plan tests => 4;
	my ($terminal) = terminal('', human => 'both',
		game => Game::Checkers->new(fen => 'B:W15,23:B11'));
	my ($jump) = grep { $_->is_jump } @{$terminal->game->legal_moves};
	ok $jump, 'the position has a capture in it';

	my $mark = $terminal->move_marks($jump);
	is $mark->{$jump->from}, 'from', 'where the piece leaves is marked';
	is $mark->{$jump->to}, 'to', 'where it lands is marked';
	is_deeply [sort map { $mark->{$_} } @{$jump->captures}],
		[('captured') x scalar @{$jump->captures}],
		'and what it takes is marked as taken';
};

subtest 'a move says what it does' => sub {
	plan tests => 4;
	my ($terminal) = terminal('', human => 'both',
		game => Game::Checkers->new(fen => 'B:W15,23:B11'));
	my ($jump) = grep { $_->is_jump } @{$terminal->game->legal_moves};
	ok $jump, 'the position has a capture in it';
	like $terminal->describe($jump), qr/^takes \w\d/, 'a jump names its victim';

	# a black man on b2 steps onto the back row and is crowned for it
	my ($crowning) = terminal('', human => 'both',
		game => Game::Checkers->new(fen => 'B:W1:B25'));
	my ($promote) = grep { $_->promoted } @{$crowning->game->legal_moves};
	ok $promote, 'and the other position has a crowning in it';
	is $crowning->describe($promote), 'crowns', 'which the move says';
};

subtest 'a long list is windowed around the choice' => sub {
	plan tests => 3;
	my ($terminal) = terminal('', human => 'both');
	# a made up list, because no legal position has twenty moves in it: the
	# windowing is what is under test, not the position
	my @legal = (@{$terminal->game->legal_moves}) x 3;
	my $lines = $terminal->choice_lines(\@legal, 0);
	is scalar(grep { m/further up/ } @{$lines}), 0, 'at the top, nothing is above';
	ok scalar(grep { m/further down/ } @{$lines}), 'but the rest is below';

	$lines = $terminal->choice_lines(\@legal, $#legal);
	ok scalar(grep { m/further up/ } @{$lines}),
		'and at the bottom it is the other way round';
};

subtest 'a painted board is checkered' => sub {
	plan tests => 5;
	my ($plain) = terminal('', colour => 0);
	my $lines = $plain->board_lines;
	like $lines->[1], qr/^   \+---\+/, 'without colour the board keeps its grid';

	my ($painted) = terminal('', colour => 1);
	my $board = $painted->board_lines;
	unlike $board->[1], qr/\+---\+/, 'with colour the grid goes';
	like $board->[1], qr/48;5;180/, 'the light squares are painted';
	like $board->[1], qr/48;5;94/, 'and so are the dark ones';

	# the file letters have to stay over the pieces, grid or no grid
	my ($row) = grep { m/^ 8 / } @{$board};
	$row =~ s/\e\[[0-9;]*m//g;
	my @piece;
	while ($row =~ m/b/g) {
		push @piece, pos($row) - 1;
	}
	my @letter;
	my $files = $board->[0];
	while ($files =~ m/[a-h]/g) {
		push @letter, pos($files) - 1;
	}
	is_deeply [@piece], [@letter[1, 3, 5, 7]],
		'a piece sits in the column its file letter is in';
};

subtest 'the highlight is only a colour, never a character' => sub {
	plan tests => 2;
	my ($terminal) = terminal('', colour => 1);
	my $before = $terminal->board_lines;
	$terminal->highlight({ 1 => 'from', 5 => 'to' });
	my $after = $terminal->board_lines;

	my @bare = map { my $line = $_; $line =~ s/\e\[[0-9;]*m//g; $line } @{$after};
	my @was = map { my $line = $_; $line =~ s/\e\[[0-9;]*m//g; $line } @{$before};
	is_deeply \@bare, \@was, 'with the colour taken out the board is unchanged';
	isnt join('', @{$after}), join('', @{$before}),
		'though the colours in it are not';
};

subtest 'no terminal, no picking' => sub {
	plan tests => 3;
	my $output = '';
	open my $out, '>', \$output or die "in memory handle: $!";
	my $typed = Game::Checkers::Terminal->new(
		out => $out,
		in => \*STDIN,
		interactive => 0,
		colour => 0,
		ascii => 1
	);
	is $typed->picking, 0, 'a terminal that was not asked to pick does not';
	is $typed->raw, 0, 'and is not put into raw mode';

	my ($picker) = terminal('', human => 'both');
	$picker->enter_raw;
	$picker->command('type');
	is $picker->raw, 0, 'the type command gives the terminal back';
};

done_testing;
