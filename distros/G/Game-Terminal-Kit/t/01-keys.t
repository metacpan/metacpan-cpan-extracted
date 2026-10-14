#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::Keys;

sub typing {
	my ($bytes, %more) = @_;
	my @chars = split //, $bytes;
	return Game::Terminal::Kit::Keys->new(keysource => sub { shift @chars }, %more);
}

subtest 'every key has its name' => sub {
	my @cases = (
		["\r", 'enter'], ["\n", 'enter'], ["\t", 'tab'],
		["\x7f", 'backspace'], ["\x08", 'backspace'],
		["\x03", 'interrupt'], ["\x04", 'eof'],
		["\e[A", 'up'], ["\e[B", 'down'], ["\e[C", 'right'], ["\e[D", 'left'],
		["\eOA", 'up'], ["\eOB", 'down'], ["\eOC", 'right'], ["\eOD", 'left'],
		["\e[H", 'home'], ["\e[F", 'end'], ["\eOH", 'home'], ["\eOF", 'end'],
		["\e[Z", 'back_tab'],
		["\e[1~", 'home'], ["\e[2~", 'insert'], ["\e[3~", 'delete'],
		["\e[4~", 'end'], ["\e[5~", 'page_up'], ["\e[6~", 'page_down'],
		["\e[7~", 'home'], ["\e[8~", 'end'],
		['a', 'a'], ['Q', 'Q'], [' ', ' '], ['?', '?'], ['[', '['],
	);
	plan tests => 2 * @cases;
	for my $case (@cases) {
		my ($bytes, $name) = @{$case};
		my $keys = typing($bytes);
		(my $shown = $bytes) =~ s/([^ -~])/sprintf '\\x%02x', ord $1/ge;
		is $keys->read_key, $name, "$shown is $name";
		is $keys->read_key, undef, "$shown left nothing behind";
	}
};

subtest 'the escape key on its own' => sub {
	plan tests => 5;
	my $keys = typing("\e");
	is $keys->read_key, 'escape', 'escape and then nothing is escape';
	is $keys->read_key, undef, 'and nothing follows';

	$keys = typing("\ex\e[B");
	is $keys->read_key, 'escape', 'escape and then a letter is escape';
	is $keys->read_key, 'x', 'the letter is the next key';
	is $keys->read_key, 'down', 'and the reader is back in step';
};

subtest 'a sequence that is not in the table' => sub {
	plan tests => 8;
	my $keys = typing("\e[1;5Aq");
	is $keys->read_key, 'unknown', 'an arrow with a modifier is unknown';
	is $keys->read_key, 'q', 'and all of it was read';

	$keys = typing("\e[12345678q");
	is $keys->read_key, 'unknown', 'eight characters with no end are unknown';
	is $keys->read_key, 'q', 'and the ninth is the next key';

	$keys = typing("\e[");
	is $keys->read_key, 'unknown', 'an opener and then nothing is unknown';
	is $keys->read_key, undef, 'and nothing follows';

	$keys = typing("\e[9~");
	is $keys->read_key, 'unknown', 'a tilde key with no name is unknown';
	is $keys->read_key, undef, 'and nothing follows';
};

subtest 'characters put back are read first, in order' => sub {
	plan tests => 5;
	my $keys = typing('z');
	is $keys->unread('a', 'b'), $keys, 'unread returns the object';
	is $keys->read_key, 'a', 'the first put back';
	$keys->unread('c');
	is $keys->read_key, 'c', 'one put back later jumps the queue';
	is $keys->read_key, 'b', 'then the second';
	is $keys->read_key, 'z', 'then the source';
};

subtest 'the wait reaches the source' => sub {
	plan tests => 7;
	my (@asked, @feed);
	my $keys = Game::Terminal::Kit::Keys->new(
		keysource => sub { push @asked, $_[0]; return shift @feed },
	);

	@feed = ('k');
	is $keys->read_key, 'k', 'a key with no wait given';
	is_deeply \@asked, [undef], 'the source was asked to wait for ever';

	@asked = ();
	@feed = (undef, 'k');
	is $keys->read_key(0.25), undef, 'no key in the time is undef';
	is $keys->read_key(0.25), 'k', 'and the key is there next time';
	is_deeply \@asked, [0.25, 0.25], 'the source was given the seconds';

	@asked = ();
	@feed = ("\e", '[', 'A');
	is $keys->read_key(0), 'up', 'a sequence read without waiting';
	is_deeply \@asked, [0, 0.05, 0.05], 'the rest of a sequence is waited for briefly';
};

subtest 'raw mode with a source only keeps the flag' => sub {
	plan tests => 7;
	my $keys = typing('');
	is $keys->raw, 0, 'not raw to begin with';
	ok $keys->keys_available, 'a source is keys';
	is $keys->enter_raw, $keys, 'enter_raw returns the object';
	is $keys->raw, 1, 'and is raw';
	is $keys->enter_raw, $keys, 'a second enter_raw is harmless';
	is $keys->leave_raw->raw, 0, 'leave_raw is not raw';
	is $keys->leave_raw->raw, 0, 'a second leave_raw is harmless';
};

subtest 'no keyboard' => sub {
	plan tests => 6;
	open my $in, '<', \"a line\n" or die $!;
	my @slept;
	my $keys = Game::Terminal::Kit::Keys->new(
		in => $in,
		sleeper => sub { push @slept, $_[0]; return },
	);
	ok !$keys->keys_available, 'a file is not a keyboard';
	is $keys->enter_raw, undef, 'enter_raw says so';
	is $keys->raw, 0, 'and is not raw';
	is $keys->read_key(0.2), undef, 'a timed read has no key';
	is $keys->read_key(0), undef, 'nor has a poll';
	is_deeply \@slept, [0.2], 'the timed read slept its time and the poll did not sleep';
};

subtest 'a whole line' => sub {
	plan tests => 9;
	open my $in, '<', \"  e3 to d4  \n\nlast" or die $!;
	my $shown = '';
	open my $out, '>', \$shown or die $!;
	my $keys = Game::Terminal::Kit::Keys->new(in => $in, keysource => sub { undef });

	$keys->enter_raw;
	is $keys->read_line('Move: ', $out), 'e3 to d4', 'the line without the space around it';
	is $shown, 'Move: ', 'the prompt was printed';
	is $keys->raw, 1, 'raw again afterwards';

	$keys->leave_raw;
	is $keys->read_line, '', 'an empty line is empty, not undef';
	is $shown, 'Move: ', 'no prompt when none was given';
	is $keys->raw, 0, 'not raw afterwards when it was not before';

	is $keys->read_line('again', undef), 'last', 'a last line with no newline';
	is $shown, 'Move: ', 'no prompt without a handle';
	is $keys->read_line, undef, 'undef at the end';
};

subtest 'the names' => sub {
	plan tests => 1;
	is_deeply [Game::Terminal::Kit::Keys->names], [qw/
		back_tab backspace delete down end enter eof escape home insert
		interrupt left page_down page_up right tab unknown up
	/], 'eighteen names, sorted';
};

done_testing;
