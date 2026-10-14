#!perl
use 5.014;
use strict;
use warnings;
use lib 't/lib/absent';
use Test::More;

use Game::Terminal::Kit::Keys;
use Game::Terminal::Kit::Screen;

plan tests => 7;

my $keys = Game::Terminal::Kit::Keys->new;
{
	no warnings 'redefine';
	local *Game::Terminal::Kit::Keys::_on_a_terminal = sub { 1 };
	ok !$keys->keys_available, 'a terminal without Term::ReadKey has no keys';
	is $keys->enter_raw, undef, 'enter_raw says so';
	is $keys->raw, 0, 'and is not raw';
	is $keys->leave_raw, $keys, 'leave_raw is still safe';
}

local %ENV = %ENV;
delete @ENV{qw/COLUMNS LINES/};
my $text = '';
open my $out, '>', \$text or die $!;
my $screen = Game::Terminal::Kit::Screen->new(out => $out, interactive => 1);
is_deeply [$screen->measured], [], 'the window cannot be measured';
is_deeply [$screen->size], [80, 24], 'so it is 80 by 24';

ok !$INC{'Term/ReadKey.pm'}, 'and Term::ReadKey was never loaded';
