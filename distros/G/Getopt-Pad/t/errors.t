use v5.26;
use experimental 'signatures';
use Test2::V0;

use Encode ();
use File::Spec;
use IPC::Open3 qw(open3);
use Symbol     qw(gensym);

my $libDir = File::Spec->rel2abs('lib');

sub runScript($code, @argv) {
	return runPerl([], $code, @argv);
}

sub runPerl($switches, $code, @argv) {
	my $stderrHandle = gensym;
	my $pid = open3(my $stdinHandle, my $stdoutHandle, $stderrHandle, $^X, $switches->@*, "-I$libDir", '-MGetopt::Pad', '-e', $code, '--', @argv);
	close $stdinHandle;
	local $/;
	# The child's handles are in text mode on Windows: normalize its CRLF.
	my $stdout = (readline($stdoutHandle) // '') =~ s/\r\n/\n/gr;
	my $stderr = (readline($stderrHandle) // '') =~ s/\r\n/\n/gr;
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
	is $exit, 255, 'exit 255, not the usage-error exit code';
	like $stderr, qr/Getopt::Pad spec: option 'owner': unknown option type 'bogus'/, 'spec error message visible';
	like $stderr, qr/ at -e line 1\.$/m, 'location is the GetOptions call, not the library';

	(undef, undef, my $nestedError) = runScript(
		'GetOptions(commands => { doc => { options => { retries => { type => q(i), default => q(three) } } } });',
	);
	like $nestedError, qr/default value: 'three' is not an integer at -e line 1\.$/m, 'nested spec error located at the call as well';

	my ($errnoExit) = runScript('GetOptions(options => { owner => { type => q(s), valid => sub { $! = 2; q(none) } } }, argv => [qw(--owner a)]);');
	is $errnoExit, 255, 'a $! set before the spec error does not change the exit status';

	(undef, undef, my $oddError) = runScript('GetOptions(options => {}, q(argv));');
	like $oddError, qr/^Getopt::Pad spec: GetOptions expects key\/value pairs at -e line 1\.$/m, 'an odd argument list is a spec error';
};

subtest 'command line words are decoded like config values' => sub {
	# A command line and a script file deliver UTF-8 bytes, while the
	# literals here are characters (Test2::V0 enables utf8).
	my $utf8 = sub ($text) { Encode::encode('UTF-8', $text) };
	my $city = $utf8->('use utf8; my $opt = GetOptions(options => { city => { type => q(s), valid => [q(Köln), q(Bonn)] } }); print length $opt->city;');

	my ($exit, $stdout) = runScript($city, '--city', $utf8->('Köln'));
	is [$exit, $stdout], [0, 4], 'a non-ASCII word matches a valid list written as characters';

	(undef, $stdout) = runPerl(['-CA'], $city, '--city', $utf8->('Köln'));
	is $stdout, 4, 'words perl -CA decoded already are not decoded twice';

	(undef, undef, my $stderr) = runScript($city, '--city', $utf8->('Kölle'));
	my $expected = $utf8->(q(ERROR: option '--city': 'Kölle' is not one of: Köln, Bonn));
	like $stderr, qr/^\Q$expected\E$/m, 'the message is printed as UTF-8';

	(undef, $stdout) = runScript('my $opt = GetOptions(options => { name => { type => q(s) } }); print length $opt->name;', '--name', "K\xF6ln");
	is $stdout, 4, 'a word that is not valid UTF-8 stays as it is';
};

done_testing;
