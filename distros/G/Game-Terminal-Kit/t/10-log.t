#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::Log;

subtest 'an empty log' => sub {
	plan tests => 3;
	my $log = Game::Terminal::Kit::Log->new;
	is_deeply [$log->lines], [], 'has no lines';
	is $log->keep, 4, 'keeps four by default';
	is_deeply [$log->shown->forget->lines], [], 'and shown and forget are harmless';
};

subtest 'records stay and the oldest goes' => sub {
	plan tests => 7;
	my $log = Game::Terminal::Kit::Log->new(keep => 2);
	is $log->record('one'), $log, 'record returns the log';
	$log->record('two a', 'two b');
	is_deeply [$log->lines], ['one', 'two a', 'two b'], 'oldest first, a record of two lines kept whole';
	$log->record('three');
	is_deeply [$log->lines], ['two a', 'two b', 'three'], 'a third pushes the first out, both its lines';
	$log->shown;
	is_deeply [$log->lines], ['two a', 'two b', 'three'], 'being shown does not drop a record';
	$log->record(undef, '')->record;
	is_deeply [$log->lines], ['two a', 'two b', 'three'], 'an empty record is not a record';
	$log->record('four', undef, '');
	is_deeply [$log->lines], ['three', 'four'], 'empty lines are left out of one';
	is_deeply [Game::Terminal::Kit::Log->new(keep => 0)->record('gone')->lines], [], 'keeping none keeps none';
};

subtest 'notes are shown once' => sub {
	plan tests => 6;
	my $log = Game::Terminal::Kit::Log->new;
	is $log->note('a remark'), $log, 'note returns the log';
	$log->record('a move');
	$log->note('another', undef, '');
	is_deeply [$log->lines], ['a move', 'a remark', 'another'], 'the records, then the notes in order';
	is_deeply [$log->lines], ['a move', 'a remark', 'another'], 'reading them does not drop them';
	is $log->shown, $log, 'shown returns the log';
	is_deeply [$log->lines], ['a move'], 'after a frame only the record is left';
	is_deeply [$log->forget->lines], [], 'forget drops that too';
};

subtest 'two logs are two logs' => sub {
	plan tests => 2;
	my $one = Game::Terminal::Kit::Log->new;
	my $two = Game::Terminal::Kit::Log->new;
	$one->record('mine')->note('mine too');
	is_deeply [$two->lines], [], 'what one is told the other does not know';
	is_deeply [$one->lines], ['mine', 'mine too'], 'and the first still does';
};

done_testing;
