#!perl
use 5.010;
use strict;
use warnings;
use File::Temp ();
use Test::More;

use Game::Checkers;

my $script = 'bin/checkers';

plan skip_all => "$script is not here, so this is not the distribution root"
	unless -f $script;

# the script is run as a process, but never an interactive one: everything it is
# asked to do here either prints and stops or reads its moves from a file.
#
# no shell is involved. the arguments go straight to the child, so a FEN does
# not have to survive a round of quoting, and the input arrives on a handle
# rather than through a pipeline, so there is no printf to find. cmd.exe has
# neither the quoting nor the printf, and that is what this used to need.
sub run {
	my (@argument) = @_;
	my $input = ref $argument[0] eq 'ARRAY' ? shift @argument : [];

	my $stdin = File::Temp->new;
	binmode $stdin;
	print {$stdin} map { "$_\n" } @{$input};
	close $stdin;

	my $stdout = File::Temp->new;
	close $stdout;

	open my $old_in, '<&', \*STDIN or die "cannot save STDIN: $!";
	open my $old_out, '>&', \*STDOUT or die "cannot save STDOUT: $!";
	open my $old_err, '>&', \*STDERR or die "cannot save STDERR: $!";

	open STDIN, '<', $stdin->filename or die "cannot read the input: $!";
	open STDOUT, '>', $stdout->filename or die "cannot write the output: $!";
	open STDERR, '>&', \*STDOUT or die "cannot merge STDERR: $!";

	my $failed = system $^X, '-Ilib', $script, @argument;
	my $status = $failed == -1 ? -1 : $? >> 8;

	open STDIN, '<&', $old_in or die "cannot restore STDIN: $!";
	open STDOUT, '>&', $old_out or die "cannot restore STDOUT: $!";
	open STDERR, '>&', $old_err or die "cannot restore STDERR: $!";

	my $output = do {
		open my $fh, '<', $stdout->filename or die "cannot read the output: $!";
		local $/;
		readline $fh;
	};

	return (defined $output ? $output : '', $status);
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
	my ($output, $status) = run('--analyse', '--fen', 'B:W21,23:B5,9,13', '--level', 3);
	is $status, 0, 'it ran';
	like $output, qr/^move 13-17$/m, 'and found the shot without a terminal';
	like $output, qr/^nodes \d+$/m, 'reporting what it cost';
	like $output, qr/^line 13-17 /m, 'and the line it expects';
};

subtest 'a game read from a handle' => sub {
	plan tests => 3;
	my ($output, $status) = run(
		[qw/f6-e5 quit y/],
		'--hotseat', '--ascii', '--no-colour'
	);
	like $output, qr/Last: f6-e5 by black/, 'the move was played';
	unlike $output, qr/\e/, 'no escape codes reached a handle that is not a terminal';
	is $status, 0, 'and it stopped cleanly';
};

subtest 'end of file is not an error' => sub {
	plan tests => 2;
	my ($output, $status) = run('--hotseat', '--ascii', '--no-colour');
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
