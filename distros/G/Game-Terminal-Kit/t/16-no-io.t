#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::Canvas;
use Game::Terminal::Kit::Choose;
use Game::Terminal::Kit::Form;
use Game::Terminal::Kit::Frame;
use Game::Terminal::Kit::History;
use Game::Terminal::Kit::Keys;
use Game::Terminal::Kit::Line;
use Game::Terminal::Kit::Log;
use Game::Terminal::Kit::Options;
use Game::Terminal::Kit::Picker;
use Game::Terminal::Kit::Screen;
use Game::Terminal::Kit::Steer;
use Game::Terminal::Kit::Test::Handle;
use Game::Terminal::Kit::Ticker;

plan tests => 13;

my @fields = (
	{ name => 'level', type => 'int', min => 1, max => 5, help => 'the strength of the bot' },
	{ name => 'seed', type => 'str', help => 'the same game again' },
);
my @keys = (qw/up down left right tab back_tab home end enter escape backspace delete q p k j x 1 9/, ' ', '?', 'eof');

sub quietly {
	my ($name, $body) = @_;
	my $lived = do {
		tie local *STDOUT, 'Game::Terminal::Kit::Test::Handle';
		tie local *STDIN, 'Game::Terminal::Kit::Test::Handle';
		eval { $body->(); 1 };
	};
	my $why = $@;
	ok $lived, $name or diag $why;
	return;
}

{
	tie local *STDOUT, 'Game::Terminal::Kit::Test::Handle';
	ok !eval { print STDOUT 'x'; 1 }, 'the handle the rest of this file trusts does refuse a print';
	tie local *STDIN, 'Game::Terminal::Kit::Test::Handle';
	ok !eval { my $line = <STDIN>; 1 }, 'and a read';
}

quietly 'a keyboard and a screen are built without reading or writing' => sub {
	my $keys = Game::Terminal::Kit::Keys->new;
	my $screen = Game::Terminal::Kit::Screen->new;
	$keys->keys_available;
	$screen->paint('text', '1');
	$screen->size;
	$screen->too_small(10, 10);
};

quietly 'a screen that is not a terminal moves no cursor' => sub {
	Game::Terminal::Kit::Screen->new->clear->rewind(3)->at(1, 1)->hide_cursor->show_cursor->restore;
};

quietly 'a picker is built, drawn and stepped' => sub {
	my $log = Game::Terminal::Kit::Log->new;
	my $picker = Game::Terminal::Kit::Picker->new(items => [qw/a b c/], log => $log, game_keys => { '?' => 'help' });
	for my $key (@keys) { $picker->lines; $picker->step($key) }
	$picker->reset([qw/x y/])->current;
};

quietly 'a picker of several' => sub {
	my $picker = Game::Terminal::Kit::Picker->new(items => [qw/a b c/], need => 2);
	for my $key (@keys) { $picker->lines; $picker->step($key) }
};

quietly 'a question' => sub {
	my $ask = Game::Terminal::Kit::Choose->new(question => 'Which', choices => [[ a => 'A' ], [ b => 'B', 'the other' ]]);
	for my $key (@keys) { $ask->lines; $ask->step($key) }
};

quietly 'a form' => sub {
	my $form = Game::Terminal::Kit::Form->new(title => 'a game', fields => \@fields, log => Game::Terminal::Kit::Log->new);
	for my $key (@keys, @keys) { $form->lines; $form->step($key) }
	$form->set('level', '9');
	$form->set('seed', 'tuesday');
	$form->argv;
};

quietly 'a line' => sub {
	my $line = Game::Terminal::Kit::Line->new(prompt => ': ');
	for my $key (@keys) { $line->lines; $line->step($key) }
};

quietly 'a canvas and its frames' => sub {
	my $canvas = Game::Terminal::Kit::Canvas->new(width => 12, height => 4);
	$canvas->fill(0, 0, 12, 4, '.', ground => '44')
		->box(1, 0, 5, 3, Game::Terminal::Kit::Frame::box('cursor', 1), ink => '1')
		->put(2, 1, 'K', ink => '31');
	$canvas->lines(Game::Terminal::Kit::Screen->new(colour => 1));
	$canvas->text;
	Game::Terminal::Kit::Frame::around('recent', 0, 'a');
	Game::Terminal::Kit::Frame::brackets('from');
};

quietly 'steering, options, a log and a ticker' => sub {
	my @points = ([0, 0], [1, 0], [0, 1]);
	Game::Terminal::Kit::Steer::ring(3, 0, 1);
	Game::Terminal::Kit::Steer::clamp(3, 0, -1);
	Game::Terminal::Kit::Steer::nearest(\@points, 0, 1, 0, cone => 1);
	Game::Terminal::Kit::Steer::axis(\@points, 0, 0, 1);
	Game::Terminal::Kit::Steer::rest(\@points);
	Game::Terminal::Kit::Options::validate(\@fields);
	Game::Terminal::Kit::Options::argv_for(\@fields, { level => 2, extra => '-x "a b"' });
	Game::Terminal::Kit::Options::step_value($fields[0], undef, 1);
	Game::Terminal::Kit::Options::check_value($fields[0], '9');
	Game::Terminal::Kit::Log->new->record('a')->note('b')->shown->forget->lines;
	Game::Terminal::Kit::Ticker->new->start(1)->tick(1)->remaining;
};

quietly 'a history kept, taken back and played again' => sub {
	my $history = Game::Terminal::Kit::History->new(save => sub { $_[0] }, load => sub { $_[0] . '!' });
	$history->start('a')->record('b')->record('c');
	$history->undo(2); $history->redo; $history->legend; $history->clear;
};

my @reads_or_writes;
for my $name (qw/Canvas Choose Form Frame History Line Log Options Picker Steer Ticker Widget/) {
	my $file = "lib/Game/Terminal/Kit/$name.pm";
	open my $fh, '<', $file or die "cannot read $file: $!";
	my $in = '';
	while (my $line = <$fh>) {
		last if $line =~ m/^__END__/;
		$in = $1 if $line =~ m/^sub (\w+)/;
		next if $in eq 'run' || $in eq 'draw';
		push @reads_or_writes, "$name\::$in line $." if $line =~ m/\bprint\b|\bprintf\b|\breadline\b|ReadKey|<\$|\bSTD(?:IN|OUT|ERR)\b/;
	}
}
is_deeply \@reads_or_writes, [], 'and in the source nothing but run and draw names a handle';
