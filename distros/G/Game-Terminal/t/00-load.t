#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

my @modules = qw/
	Game::Terminal
	Game::Terminal::Menu
/;

plan tests => scalar(@modules) + 1;

use_ok($_) for @modules;

my %version;
no strict 'refs';
$version{${"${_}::VERSION"}}++ for @modules;
use strict 'refs';

is scalar(keys %version), 1,
	'every module carries the same $VERSION (' . join(', ', keys %version) . ')';

diag("Testing Game::Terminal $Game::Terminal::VERSION, Perl $], $^X");
