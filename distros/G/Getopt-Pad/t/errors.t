use v5.26;
use experimental 'signatures';
use Test2::V0;

use File::Spec;
use IPC::Open3 qw(open3);
use Symbol     qw(gensym);

my $libDir = File::Spec->rel2abs('lib');

sub runScript($code, @argv) {
	my $stderrHandle = gensym;
	my $pid = open3(my $stdinHandle, my $stdoutHandle, $stderrHandle, $^X, "-I$libDir", '-MGetopt::Pad', '-e', $code, '--', @argv);
	close $stdinHandle;
	local $/;
	my $stdout = readline($stdoutHandle) // '';
	my $stderr = readline($stderrHandle) // '';
	waitpid $pid, 0;
	return ($? >> 8, $stdout, $stderr);
}

subtest 'success path' => sub {
	my ($exit, $stdout, $stderr) = runScript(
		'my $opt = GetOptions(options => { owner => { type => q(s) } }); print $opt->owner;',
		'--owner', 'dave',
	);
	is $exit,   0,      'exit 0';
	is $stdout, 'dave', 'value reaches the reader';
	is $stderr, '',     'no noise on STDERR';
};

subtest 'user error exits 2 with message and hint' => sub {
	my ($exit, $stdout, $stderr) = runScript(
		'GetOptions(options => { owner => { type => q(s), required => 1 } }); print q(unreached);',
	);
	is $exit,   2,  'exit code 2';
	is $stdout, '', 'nothing on STDOUT';
	like $stderr, qr/^ERROR: missing required option '--owner'/m, 'ERROR-prefixed specific message (plain without a tty)';
	like $stderr, qr/^# .*\[options\]/m, 'help text follows the error';
	like $stderr, qr/^   --owner <>/m, 'option documented in the help text';
};

subtest 'spec errors are programmer errors, not usage errors' => sub {
	my ($exit, $stdout, $stderr) = runScript(
		'GetOptions(options => { owner => { type => q(bogus) } });',
	);
	isnt $exit, 0, 'non-zero exit';
	isnt $exit, 2, 'not the usage-error exit code';
	like $stderr, qr/Getopt::Pad spec: unknown option type 'bogus'/, 'spec error message visible';
	like $stderr, qr/ at -e line 1\.$/m, 'location is the GetOptions call, not the library';

	(undef, undef, my $nestedError) = runScript(
		'GetOptions(commands => { doc => { options => { retries => { type => q(i), default => q(three) } } } });',
	);
	like $nestedError, qr/default value: 'three' is not an integer at -e line 1\.$/m, 'nested spec error located at the call as well';
};

done_testing;
