#!perl
use 5.014;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Terminal;
use Game::Fake::Terminal;

my $row = { key => 'fake', class => 'Game::Fake::Terminal' };
my $fake = sub { 'Game::Fake::Terminal' };

subtest 'the fields are the game\'s own' => sub {
	plan tests => 5;
	my $fields = Game::Terminal::options_for($row, loader => $fake);
	is_deeply [map { $_->{name} } @{$fields}], [qw/level watch/], 'what the class returns';
	isnt Game::Terminal::options_for($row, loader => $fake), $fields, 'asked again each time';
	is_deeply [Game::Terminal::argv_for($row, { watch => 1, level => 2, extra => '-x "a b"' }, loader => $fake)],
		['--level', 2, '--watch', '-x', 'a b'], 'and the command line is made from them, in their order';
	is_deeply [Game::Terminal::argv_for($row, {}, loader => $fake)], [], 'nothing set sends nothing';
	is_deeply [Game::Terminal::argv_for($row, undef, loader => $fake)], [], 'nor do no values';
};

subtest 'a game that cannot be asked has none' => sub {
	plan tests => 6;
	{
		package Game::Fake::Silent;
		sub run { return 0 }
	}
	{
		package Game::Fake::Broken;
		sub run { return 0 }
		sub options { die "no\n" }
	}
	{
		package Game::Fake::Wrong;
		sub run { return 0 }
		sub options { return 'level' }
	}
	is_deeply Game::Terminal::options_for($row, loader => sub { 'Game::Fake::Silent' }), [], 'a class with no options method';
	is_deeply Game::Terminal::options_for($row, loader => sub { 'Game::Fake::Broken' }), [], 'one whose method dies';
	is_deeply Game::Terminal::options_for($row, loader => sub { 'Game::Fake::Wrong' }), [], 'one that returns something else';
	is_deeply Game::Terminal::options_for($row, loader => sub { die "not installed\n" }), [], 'a game that does not load';
	is_deeply Game::Terminal::options_for({ key => 'none', class => 'Game::Fake::NotThere' }), [], 'through the real loader too';
	is_deeply [Game::Terminal::argv_for($row, { level => 2 }, loader => sub { 'Game::Fake::Silent' })], [],
		'and a value for a field it does not have is not sent';
};

subtest 'a row that carries its own' => sub {
	plan tests => 2;
	my $own = { %{$row}, options => [{ name => 'size', type => 'int', min => 1, max => 3, help => 'how big' }] };
	is Game::Terminal::options_for($own, loader => sub { die "never asked\n" }), $own->{options}, 'is believed without loading the class';
	is_deeply [Game::Terminal::argv_for($own, { size => 2 })], ['--size', 2], 'and used';
};

subtest 'the roster no longer holds anyone\'s options' => sub {
	plan tests => 3;
	is scalar(grep { exists $_->{options} } Game::Terminal::games()), 0, 'no row has an options list';
	is Game::Terminal::step_value({ type => 'int', min => 1, max => 5 }, undef, 1), 1, 'step_value still answers here';
	is_deeply [Game::Terminal::check_value({ name => 'level', type => 'int', min => 1, max => 5 }, '9')],
		[undef, 'level takes a whole number from 1 to 5'], 'and so does check_value';
};

done_testing;
