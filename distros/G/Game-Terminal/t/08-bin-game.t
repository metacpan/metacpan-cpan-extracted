#!perl
use 5.014;
use strict;
use warnings;
use File::Temp ();
use Test::More;

use Game::Terminal;

my $script = 'bin/game';

plan skip_all => "$script is not here, so this is not the distribution root"
	unless -f $script;
plan skip_all => 'the process test needs a Unix-like system' if $^O eq 'MSWin32';

my @libs = ('-It/lib', map { "-I$_" } grep { !ref } @INC);

sub run {
	my (@argument) = @_;
	my $stdout = File::Temp->new;
	close $stdout;
	my $stderr = File::Temp->new;
	close $stderr;

	open my $old_out, '>&', \*STDOUT or die "cannot save STDOUT: $!";
	open my $old_err, '>&', \*STDERR or die "cannot save STDERR: $!";
	open STDOUT, '>', $stdout->filename or die "cannot write the output: $!";
	open STDERR, '>', $stderr->filename or die "cannot write the errors: $!";

	local $ENV{NO_COLOR} = 1;
	my $failed = system $^X, @libs, $script, @argument;
	my $status = $failed == -1 ? -1 : $? >> 8;

	open STDOUT, '>&', $old_out or die "cannot restore STDOUT: $!";
	open STDERR, '>&', $old_err or die "cannot restore STDERR: $!";

	my $slurp = sub {
		open my $fh, '<', shift or die "cannot read: $!";
		local $/;
		my $text = readline $fh;
		return defined $text ? $text : '';
	};
	return ($slurp->($stdout->filename), $slurp->($stderr->filename), $status);
}

subtest 'version and help' => sub {
	plan tests => 6;
	my ($out, $err, $status) = run('--version');
	like $out, qr/\Q$Game::Terminal::VERSION\E/, 'the version is the dist version';
	is $status, 0, 'and it is not an error to ask';
	($out, $err, $status) = run('--help');
	like $out, qr/game list/, 'the usage names list';
	like $out, qr/game help <name>/, 'and help';
	like $out, qr/^  checkers /m, 'and the roster';
	is $status, 0, 'for status 0';
};

subtest 'list' => sub {
	plan tests => 3;
	my ($out, $err, $status) = run('list');
	is $status, 0, 'status 0';
	my @lines = split /\n/, $out;
	is scalar @lines, 21, 'twenty-one rows';
	like $out, qr/^checkers .*Game::Checkers::Terminal 9\.99$/m, 'the shadow in t/lib is the checkers found';
};

subtest 'a game is started in-process with its arguments' => sub {
	plan tests => 3;
	my ($out, $err, $status) = run('checkers', '--level', '3');
	is $out, "stub checkers: --level 3\n", 'the shadow ran with the arguments';
	is $err, '', 'nothing on stderr';
	is $status, 3, 'and its status is the exit status';
};

subtest 'an alias, the launcher flags, and help <name>' => sub {
	plan tests => 3;
	my ($out) = run('draughts');
	is $out, "stub checkers: \n", 'draughts is checkers';
	($out) = run('--ascii', '--no-pick', 'checkers', '--x');
	is $out, "stub checkers: --ascii --no-pick --x\n", 'the flags come first in the game\'s words';
	($out) = run('help', 'checkers');
	is $out, "stub checkers: --help\n", 'help <name> is <name> --help';
};

subtest 'a name that is no game' => sub {
	plan tests => 3;
	my ($out, $err, $status) = run('chekers');
	is $status, 2, 'status 2';
	like $err, qr/no such game 'chekers'\. Did you mean checkers\?/, 'with the suggestion on stderr';
	is $out, '', 'and nothing on stdout';
};

subtest 'a bad option to game itself' => sub {
	plan tests => 3;
	my ($out, $err, $status) = run('--bogus');
	is $status, 2, 'status 2';
	like $err, qr/usage: game/, 'the usage on stderr';
	is $out, '', 'and nothing on stdout';
};

done_testing;
