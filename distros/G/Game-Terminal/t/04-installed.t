#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal;

my $checkers = Game::Terminal::find('checkers');
my $maze = Game::Terminal::find('maze');

is Game::Terminal::module_file($checkers), 'Game/Checkers/Terminal.pm', 'the file of a Terminal class';
is Game::Terminal::module_file($maze), 'Term/Maze.pm', 'and of a class that is the module';

is Game::Terminal::installed($checkers, 't/lib'), 't/lib/Game/Checkers/Terminal.pm',
	'the shadow in t/lib is found when t/lib is the only place looked';
is Game::Terminal::installed($maze, 't/lib'), undef, 'and a game with no file there is not';
is Game::Terminal::installed($checkers, 't/nowhere', 't/lib'), 't/lib/Game/Checkers/Terminal.pm',
	'a missing directory is skipped';

is Game::Terminal::version_of($checkers, 't/lib'), '9.99', 'the version is read from the file';
is Game::Terminal::version_of($maze, 't/lib'), undef, 'and is undef where there is no file';

my $count = grep { Game::Terminal::installed($_, 't/lib') } Game::Terminal::games();
is $count, 1, 'exactly one row is installed under t/lib';

done_testing;
