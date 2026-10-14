#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

my @modules = qw/
	Game::Terminal::Kit
	Game::Terminal::Kit::Keys
	Game::Terminal::Kit::Screen
	Game::Terminal::Kit::Canvas
	Game::Terminal::Kit::Frame
	Game::Terminal::Kit::Steer
	Game::Terminal::Kit::Widget
	Game::Terminal::Kit::Log
	Game::Terminal::Kit::Line
	Game::Terminal::Kit::Picker
	Game::Terminal::Kit::Choose
	Game::Terminal::Kit::Form
	Game::Terminal::Kit::History
	Game::Terminal::Kit::Run
	Game::Terminal::Kit::Options
	Game::Terminal::Kit::Ticker
	Game::Terminal::Kit::Test::Handle
	Game::Terminal::Kit::Test::Screen
/;

plan tests => scalar(@modules) + 1;

use_ok($_) for @modules;

my %version;
no strict 'refs';
$version{${"${_}::VERSION"}}++ for @modules;
use strict 'refs';

is scalar(keys %version), 1,
	'every module carries the same $VERSION (' . join(', ', keys %version) . ')';

diag("Testing Game::Terminal::Kit $Game::Terminal::Kit::VERSION, Perl $], $^X");
