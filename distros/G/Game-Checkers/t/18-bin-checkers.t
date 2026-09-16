#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;

my $script = 'bin/checkers';

plan skip_all => "$script is not here, so this is not the distribution root"
	unless -f $script;

# the script is run as a process, but never an interactive one: everything it is
# asked to do here either prints and stops or reads its moves from a pipe
sub run {
	my (@argument) = @_;
	my $input = ref $argument[0] eq 'ARRAY' ? shift @argument : [];
	my $command = join ' ', $^X, '-Ilib', $script, @argument;
	$command = 'printf ' . join('', map { "'$_\\n'" } @{$input}) . " | $command"
		if @{$input};
	my $output = `$command 2>&1`;
	return ($output, $? >> 8);
}

subtest 'version and help' => sub {
	plan tests => 4;
	my ($version, $status) = run('--version');
	like $version, qr/\Q$Game::Checkers::VERSION\E/, 'the version is the dist version';
	is $status, 0, 'and it is not an error to ask';

	my ($usage, $help_status) = run('--help');
	like $usage, qr/--hotseat/, 'the usage lists the options';
	is $help_status, 0, 'and asking for help is not a failure either';
};

subtest 'analyse' => sub {
	plan tests => 4;
	# the two for one shot from t/14: the answer is known and does not depend
	# on the bot's tuning
	my ($output, $status) = run('--analyse', '--fen', q|'B:W21,23:B5,9,13'|, '--level', 3);
	is $status, 0, 'it ran';
	like $output, qr/^move 13-17$/m, 'and found the shot without a terminal';
	like $output, qr/^nodes \d+$/m, 'reporting what it cost';
	like $output, qr/^line 13-17 /m, 'and the line it expects';
};

subtest 'a piped game' => sub {
	plan tests => 3;
	my ($output, $status) = run(
		[qw/f6-e5 quit y/],
		'--hotseat', '--ascii', '--no-colour'
	);
	like $output, qr/Last: f6-e5 by black/, 'the move was played';
	unlike $output, qr/\e/, 'no escape codes went down the pipe';
	is $status, 0, 'and it stopped cleanly';
};

subtest 'end of file is not an error' => sub {
	plan tests => 2;
	my ($output, $status) = run('--hotseat', '--ascii', '--no-colour', '< /dev/null');
	like $output, qr/Bye\./, 'the game said goodbye';
	is $status, 0, 'and exited zero';
};

subtest 'a level that does not exist' => sub {
	plan tests => 2;
	my ($output, $status) = run('--level', 9);
	like $output, qr/level must be 1 to 5/, 'it says so';
	isnt $status, 0, 'and exits with a failure';
};

done_testing;
