#!perl

use strict;
use warnings;

use Config;
use Test::More 0.89;

use ExtUtils::Builder::Action::Function;
use lib 't/lib';
use Test::LivesOK 'lives_ok';

{
	my $action;
	our $callback = sub {};
	my %args = (
		function => 'callback',
		module => 'Function',
		message => 'callback',
		arguments => [ 1 ],
		exports => 1,
	);
	lives_ok { $action = ExtUtils::Builder::Action::Function->new(%args) } 'Can create new object';

	{
		my @actions;
		local $callback = sub { push @actions, 1 };

		lives_ok { $action->execute(quiet => 1) } 'Can execute command';
		is_deeply(\@actions, [1], 'Command is executed quietly');
	}

	{
		my (@actions, @messages);
		local $callback = sub { push @actions, 2 };

		lives_ok { $action->execute(logger => sub { push @messages, @_ }) } 'Can execute command';

		is_deeply(\@actions, [2], 'Command is executed with logging');
		is_deeply(\@messages, [ 'callback' ], 'Got the message');
	}

	my @serialized = $action->to_command;
	is(scalar(@serialized), 1, 'Got one command');
	my ($command, @arguments) = @{ shift @serialized };
	ok(-x $command, 'Command is executable');
	is_deeply(\@arguments, [ '-MFunction', '-e', 'callback(1)' ], 'to_command gives correct arguments');
	is($action->to_code, 'require Function; Function::callback(1)', 'to_code is "$input"');

	is($action->preference, 'execute', 'Prefered means is "execute"');
	is($action->preference(qw/code command/), 'code', 'Prefered means between "code" and "command" is "code"');
}

done_testing;

