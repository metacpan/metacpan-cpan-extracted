#! perl

use strict;
use warnings;

use Test::More 0.89;

use ExtUtils::Builder::Action::Command;
use lib 't/lib';
use Test::LivesOK 'lives_ok';

{
	my $action;
	lives_ok { $action = ExtUtils::Builder::Action::Command->new(command => [ $^X, '-e0' ]) } 'Can create new object';

	is_deeply($action->to_command, [$^X, '-e0'], 'Returns perl -e0');

	like($action->to_code, qr/ system \( '.*?','-e0' \) \ and \ die /x, 'to_code returns something that might be sensible');

	lives_ok { $action->execute(quiet => 1) } 'Can execute quiet command';

	open my $stdout, '>', \my $output;
	select $stdout;
	lives_ok { $action->execute } 'Can execute logging command';
	select STDOUT;
	close $stdout;

	like($output, qr/\Q$^X\E .+ -e0 \n \z/x, "Got '$^X -e0' as message");

	is($action->preference, 'command', 'Preferred action is "execute"');
}

{
	my $action;
	lives_ok { $action = ExtUtils::Builder::Action::Command->new(command => 'echo Hello World') } 'Can create new object';

	is_deeply($action->to_command, 'echo Hello World', 'Returns perl -e0');

	like($action->to_code, qr/ system \( 'echo\ Hello\ World' \) \ and \ die /x, 'to_code returns something that might be sensible');

	open my $stdout, '>&', *STDOUT or die;
	open my $temp, '+>:crlf', undef or die;
	open STDOUT, '>&', $temp or die;
	open my $messenger, '>', \my $message;
	select $messenger;
	lives_ok { $action->execute } 'Can execute logging command';
	select STDOUT;
	seek($temp, 0, 0);
	my $output = join '', <$temp>;
	open STDOUT, '>&', $stdout or die;
	select STDOUT;

	is($message, "echo Hello World\n", "Got echo Hello World as message");
	is($output, "Hello World\n", 'got Hello World as output');

	is($action->preference, 'command', 'Preferred action is "execute"');
}

done_testing;

