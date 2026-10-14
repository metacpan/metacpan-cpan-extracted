#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::Canvas;
use Game::Terminal::Kit::Frame;
use Game::Terminal::Kit::Log;
use Game::Terminal::Kit::Picker;
use Game::Terminal::Kit::Run;
use Game::Terminal::Kit::Test::Screen qw/kit within/;

{
	package Heaps;

	sub new {
		my ($class, %given) = @_;
		return bless { heaps => [3, 1, 2], taken => [], %given }, $class;
	}

	sub drawn {
		my ($self) = @_;
		return [ map { { label => "heap $_", value => $_ - 1, skip => !$self->{heaps}[ $_ - 1 ] } } 1 .. 3 ];
	}

	sub board {
		my ($self, $under) = @_;
		my $canvas = Game::Terminal::Kit::Canvas->new(width => 17, height => 3);
		for my $heap (0 .. 2) {
			my $mark = defined $under && $heap == $under ? 'cursor'
				: (grep { $_ == $heap } @{ $self->{taken} }) ? 'recent' : 'plain';
			$canvas->box(6 * $heap, 0, 5, 3, Game::Terminal::Kit::Frame::box($mark, 1));
			$canvas->put(6 * $heap + 2, 1, $self->{heaps}[$heap]);
		}
		return $canvas->text;
	}

	sub play {
		my ($self) = @_;
		my ($keys, $screen, $log) = @{$self}{qw/keys screen log/};
		my $picker = Game::Terminal::Kit::Picker->new(
			items => $self->drawn, log => $log, numbered => 0,
			legend => ['', 'left and right, enter to take one, q to stop'],
		);
		$keys->enter_raw;
		$screen->hide_cursor;
		while (grep { $_ } @{ $self->{heaps} }) {
			my ($event, $heap);
			while (1) {
				$picker->head([ $self->board($picker->current), '' ]);
				Game::Terminal::Kit::Widget::draw($picker, $screen);
				$self->{frames}++;
				my $key = $keys->read_key;
				($event, $heap) = defined $key ? $picker->step($key) : ('quit');
				last unless Game::Terminal::Kit::Widget::goes_on($event);
			}
			return 'stopped' if $event ne 'chosen';
			$self->{heaps}[$heap]--;
			$self->{taken} = [$heap];
			$log->record('You took one from heap ' . ($heap + 1) . '.');
			$picker->reset($self->drawn);
		}
		return 'cleared';
	}
}

sub game {
	my ($bytes, %screen) = @_;
	my ($keys, $screen, $text) = kit(keys => $bytes, %screen);
	my $log = Game::Terminal::Kit::Log->new(keep => 1);
	return (Heaps->new(keys => $keys, screen => $screen, log => $log), $text);
}

subtest 'one frame, drawn from the parts' => sub {
	plan tests => 2;
	my ($game, $text) = game('q');
	my $result = within(10, sub { Game::Terminal::Kit::Run::guard(sub { $game->play }, $game->{keys}, $game->{screen}) });
	is $result, 'stopped', 'q stops';
	is ${$text}, join("\n",
		'+===+ +---+ +---+',
		'| 3 | | 1 | | 2 |',
		'+===+ +---+ +---+',
		'',
		' > heap 1',
		'   heap 2',
		'   heap 3',
		'',
		'left and right, enter to take one, q to stop',
		'',
	), 'the cursor is a heavier box round the heap the picker is on';
};

subtest 'a move is still on screen while the next is chosen' => sub {
	plan tests => 7;
	my ($game, $text) = game("\e[C\r\e[D\rq");
	my $result = within(10, sub { Game::Terminal::Kit::Run::guard(sub { $game->play }, $game->{keys}, $game->{screen}) });
	is $result, 'stopped', 'right, enter, left, enter, q';
	is_deeply $game->{heaps}, [3, 0, 1], 'one from heap 2, then left from heap 1 round to heap 3';
	is $game->{frames}, 5, 'a frame before each of the five keys';

	my @frames = split /(?<=q to stop\n)/, ${$text};
	is scalar(@frames), 5, 'and five frames on the screen';
	is_deeply [map { scalar(() = m/^You took one from heap \d\.$/mg) } @frames], [0, 0, 1, 1, 1],
		'every frame after the first move says what the last move was, once';
	like $frames[2], qr{\A\+===\+ #===# \+---\+\n\| 3 \| \| 0 \| \| 2 \|\n},
		'the heap just taken from is marked one way and the cursor, back at rest, another';
	like $frames[3], qr{\A\+---\+ #===# \+===\+\n},
		'and left from the first heap goes round to the third';
};

subtest 'played to the end' => sub {
	plan tests => 4;
	my ($game, $text) = game("\r" x 6);
	my $result = within(10, sub { Game::Terminal::Kit::Run::guard(sub { $game->play }, $game->{keys}, $game->{screen}) });
	is $result, 'cleared', 'enter six times takes everything';
	is_deeply $game->{heaps}, [0, 0, 0], 'the cursor having moved on each time a heap ran out';
	is $game->{frames}, 6, 'in six frames';
	is_deeply [$game->{log}->lines], ['You took one from heap 3.'], 'the log keeps the last move only, as asked';
};

subtest 'the terminal is given back however it ends' => sub {
	plan tests => 9;
	my ($game, $text) = game("\r", interactive => 1);
	my $result = within(10, sub { Game::Terminal::Kit::Run::guard(sub { $game->play }, $game->{keys}, $game->{screen}) });
	is $result, 'stopped', 'the keys ran out';
	is $game->{keys}->raw, 0, 'the keyboard was given back';
	is $game->{screen}->cursor_hidden, 0, 'and the cursor';
	like ${$text}, qr/\A\e\[\?25l\e\[H/, 'which was hidden before the first frame';
	like ${$text}, qr/\e\[J\e\[\?25h\z/, 'and shown after the last';

	($game, $text) = game("\r", interactive => 1);
	$game->{log} = undef;
	my $lived = eval { Game::Terminal::Kit::Run::guard(sub { $game->play }, $game->{keys}, $game->{screen}); 1 };
	ok !$lived, 'a game that dies still dies';
	like $@, qr/record/, 'of its own error';
	is $game->{keys}->raw, 0, 'with the keyboard given back';
	like ${$text}, qr/\e\[\?25h\z/, 'and the cursor shown';
};

done_testing;
