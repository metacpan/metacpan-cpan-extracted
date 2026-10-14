#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::Ticker;

my $now = 100;
sub ticker { return Game::Terminal::Kit::Ticker->new(clock => sub { $now }) }
sub near { my ($got, $want, $name) = @_; return ok abs($got - $want) < 1e-9, "$name ($got)" }

subtest 'before it is started' => sub {
	plan tests => 4;
	my $ticker = ticker();
	is $ticker->remaining, 0, 'nothing remains';
	is $ticker->due, 1, 'so a step is due';
	is $ticker->ticks, 0, 'no steps yet';
	is $ticker->late, 0, 'and none late';
};

subtest 'a steady game' => sub {
	plan tests => 12;
	$now = 100;
	my $ticker = ticker();
	is $ticker->start(0.5), $ticker, 'start returns the ticker';
	near $ticker->remaining, 0.5, 'a whole period remains';
	is $ticker->due, 0, 'not due';
	$now = 100.4;
	near $ticker->remaining, 0.1, 'a tenth remains';
	is $ticker->due, 0, 'still not due';
	$now = 100.5;
	is $ticker->remaining, 0, 'nothing remains on the dot';
	is $ticker->due, 1, 'due';
	$now = 100.6;
	is $ticker->remaining, 0, 'never negative';
	is $ticker->tick(0.5), $ticker, 'tick returns the ticker';
	near $ticker->remaining, 0.4, 'the next is a period after the last was due, not after now';
	is $ticker->ticks, 1, 'one step';
	is $ticker->late, 0, 'a step a little late is not counted late';
};

subtest 'a stall' => sub {
	plan tests => 5;
	$now = 200;
	my $ticker = ticker()->start(0.5);
	$now = 203;
	$ticker->tick(0.5);
	near $ticker->remaining, 0.5, 'the schedule starts again from now';
	is $ticker->late, 1, 'and the step is counted late';
	is $ticker->ticks, 1, 'as one step, not six';
	$now = 203.5;
	$ticker->tick(0.25);
	near $ticker->remaining, 0.25, 'a new period applies from the next step';
	is $ticker->late, 1, 'which was on time';
};

subtest 'the real clock' => sub {
	plan tests => 3;
	my $ticker = Game::Terminal::Kit::Ticker->new;
	is ref $ticker->clock, 'CODE', 'there is a clock by default';
	$ticker->start(60);
	ok $ticker->remaining > 59 && $ticker->remaining <= 60, 'and it tells the time';
	is $ticker->tick(60)->ticks, 1, 'tick with no start before it';
};

done_testing;
