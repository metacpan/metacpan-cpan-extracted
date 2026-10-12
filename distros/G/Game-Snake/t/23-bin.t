#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use Test::More;
use IPC::Open3 ();
use Symbol ();
use File::Temp ();

use Game::Snake::Terminal;

# THE METHOD FIRST, THEN THE PROGRAM. bin/snake is two lines over
# Game::Snake::Terminal->run(@ARGV), so the options, the usage and the exit
# legend are tested by calling run with the three handles localised, and the
# program itself is started once as a process, with no shell, to prove the
# two lines are those two lines.

sub run {
	my (@argv) = @_;
	my ($out, $err) = ('', '');
	my $typed = '';
	open my $o, '>', \$out or die $!;
	open my $e, '>', \$err or die $!;
	open my $i, '<', \$typed or die $!;
	my $status = do {
		local *STDOUT = $o;
		local *STDERR = $e;
		local *STDIN  = $i;
		Game::Snake::Terminal->run(@argv);
	};
	return ($status, $out, $err);
}

subtest 'what it says of itself' => sub {
	my ($status, $out, $err) = run('--version');
	is($status, 0, '--version is 0');
	is($out, "snake $Game::Snake::Terminal::VERSION\n", 'with the version');
	is($err, '', 'and nothing on STDERR');

	($status, $out, $err) = run('--help');
	is($status, 0, '--help is 0');
	like($out, qr/^usage: snake/, 'usage on STDOUT');
	like($out, qr/^  --$_\b/m, "names --$_") for qw/ cols seed watch level ticks quiet ascii colour raylib cell version /;
	like($out, qr/exit status: 0 the game ended or you quit; 2 a bad option/, 'and carries the exit legend');
	is($err, '', 'nothing on STDERR');
};

subtest 'a bad option is 2, on STDERR' => sub {
	my ($status, $out, $err) = run('--nope');
	is($status, 2, '--nope is 2');
	like($err, qr/^snake: Unknown option: nope/m, 'named');
	like($err, qr/^usage: snake/m, 'with the usage');
	is($out, '', 'nothing on STDOUT');

	($status, $out, $err) = run('extra');
	is($status, 2, 'a stray word is 2');
	like($err, qr/^snake: I do not know 'extra'\.$/m, 'named');

	($status, $out, $err) = run('--level', '9', '--watch', '--ticks', '3');
	is($status, 2, 'a level off the ladder is 2');
	is($err, "snake: a level is one of 1 2, not '9'.\n", 'in one sentence, no file and line');

	($status, $out, $err) = run('--cols', '3', '--watch', '--ticks', '3');
	is($status, 2, 'a board too small is 2');
	is($err, "snake: a board is at least 6 by 6.\n", 'said so');
};

subtest 'no terminal and no watch cannot play' => sub {
	local @INC = ("$FindBin::Bin/lib/absent", @INC);
	local %INC = %INC;
	delete $INC{'Term/ReadKey.pm'};
	my ($status, $out, $err) = run('--cols', '10', '--rows', '8');
	is($status, 2, 'exit 2');
	like($err, qr/^snake: A real-time game needs a terminal and Term::ReadKey/, 'the sentence on STDERR');
	is($out, '', 'nothing on STDOUT');
};

subtest 'watch on a pipe plays to its cap' => sub {
	my ($status, $out, $err) = run('--watch', '--seed', 'pipe', '--cols', '10', '--rows', '8', '--ticks', '12', '--quiet');
	is($status, 0, 'exit 0');
	is($err, '', 'nothing on STDERR');
	like($out, qr/^Quit at \d+ points, \d+ long$/m, 'the result sentence');

	($status, $out, $err) = run('--watch', '--seed', 'pipe', '--cols', '10', '--rows', '8', '--ticks', '3', '--ascii', '--no-colour');
	is($status, 0, 'exit 0 with frames');
	my @frames = $out =~ /^ Snake   score/mg;
	is(scalar @frames, 4, 'four frames for three ticks');
	unlike($out, qr/\e/, 'and no escape on a pipe');
};

subtest 'the program, as a process' => sub {
	my $script = "$FindBin::Bin/../bin/snake";
	ok(-f $script, 'bin/snake is there');
	my $dir = File::Temp->newdir;
	my $in_file = "$dir/in";
	open my $w, '>', $in_file or die $!;
	close $w;
	open my $in, '<', $in_file or die $!;
	my $err = Symbol::gensym();
	my $pid = IPC::Open3::open3('<&' . fileno($in), my $out, $err,
		$^X, "-I$FindBin::Bin/lib/absent", (map { "-I$_" } grep { !ref } @INC), $script,
		'--watch', '--seed', 'process', '--cols', '10', '--rows', '8', '--ticks', '20', '--quiet');
	my $said = do { local $/; <$out> } // '';
	my $wrong = do { local $/; <$err> } // '';
	waitpid $pid, 0;
	is($? >> 8, 0, 'exit 0 with Term::ReadKey absent and no terminal');
	like($said, qr/^Quit at \d+ points, \d+ long$/m, 'and the sentence');
	is($wrong, '', 'nothing on STDERR');

	$pid = IPC::Open3::open3('<&' . fileno($in), $out, $err,
		$^X, "-I$FindBin::Bin/lib/absent", (map { "-I$_" } grep { !ref } @INC), $script, '--cols', '10', '--rows', '8');
	$said = do { local $/; <$out> } // '';
	$wrong = do { local $/; <$err> } // '';
	waitpid $pid, 0;
	is($? >> 8, 2, 'and without --watch, exit 2');
	like($wrong, qr/^snake: A real-time game needs a terminal/, 'with the sentence on STDERR');
};

done_testing();
