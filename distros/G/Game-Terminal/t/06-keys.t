#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Menu;

sub menu {
	my ($keys, %option) = @_;
	my @chars = split //, defined $keys ? $keys : '';
	my $output = '';
	open my $out, '>', \$output or die "in memory handle: $!";
	my $menu = Game::Terminal::Menu->new(
		out => $out,
		interactive => 0,
		colour => 0,
		keysource => sub { shift @chars },
		picking => 1,
		%option
	);
	return ($menu, \$output, \@chars);
}

subtest 'a key at a time, named' => sub {
	plan tests => 2;
	my ($menu) = menu("k\e[A\e[B\e[C\e[D\e[5~\eOH\r\t\x7f\x03\x04 q\e\e[6~");
	my @got;
	while (defined(my $key = $menu->read_key)) {
		push @got, $key eq ' ' ? 'space' : $key;
	}
	is_deeply \@got, [qw/k up down right left page_up home enter tab backspace
		interrupt eof space q escape page_down/],
		'a character comes back as itself and a sequence as a name';

	my ($named) = menu("\e[A");
	ok length($named->read_key) > 1, 'so a name is the longer of the two';
};

subtest 'an escape does not eat the key behind it' => sub {
	plan tests => 2;
	my ($menu) = menu("\eq");
	is $menu->read_key, 'escape', 'the escape is an escape';
	is $menu->read_key, 'q', 'and the keystroke behind it survives';
};

subtest 'raw mode with a keysource touches no terminal' => sub {
	plan tests => 3;
	my ($menu) = menu('');
	ok $menu->keys_available, 'keys are available through the seam';
	ok $menu->enter_raw, 'entering raw mode succeeds';
	ok $menu->leave_raw && !$menu->raw, 'and leaving it clears the flag';
};

done_testing;
