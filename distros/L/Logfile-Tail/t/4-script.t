
use Test::More tests => 75;

use IPC::Open3 ();
use Symbol ();
use Cwd ();

require 't/lib.pl';

my @opts;
if (defined $ENV{HARNESS_PERL_SWITCHES}) {
	@opts = ( $ENV{HARNESS_PERL_SWITCHES} );
}

my $script = './blib/script/logfile-tail';
my ($pipe, $data);

ok(open($pipe, '-|', $^X, @opts, $script, '-h'), 'check that logfile-tail has the -h (--help) option');
{
local $/ = undef;
$data = <$pipe>;
}
like($data, qr/^Usage:/, '  and it prints the usage summary');
is(close($pipe), 1, 'close the pipe');
is($?, 0, 'the exit code should be zero');

my ($in, $out, $err);
my $pid;

$err = Symbol::gensym();
ok(($pid = IPC::Open3::open3($in, $out, $err, $^X, @opts, $script, '--badoption')), 'check logfile-tail with bad command line parameter');
ok(close $in, 'no input');
{
local $/ = undef;
$data = <$err>;
}
like($data, qr/badoption/, '  stderr should complain about the bad parameter');
ok(close $err, '  closing stderr');
{
local $/ = undef;
$data = <$out>;
}
is($data, '', '  should print no output');
ok(close $out, '  closing stdout');
ok(waitpid($pid, 0), 'let the script finish');
is($?, 256, 'the exit code should be nonzero');


ok(($pid = IPC::Open3::open3($in, $out, $err, $^X, @opts, $script)), 'run logfile-tail with no parameter');
ok(close $in, 'no input');
{
local $/ = undef;
$data = <$err>;
}
like($data, qr/^Usage:/, '  stderr should show usage');
ok(close $err, '  closing stderr');
{
local $/ = undef;
$data = <$out>;
}
is($data, undef, '  and stdout should have no output');
ok(close $out, '  closing stdout');
ok(waitpid($pid, 0), 'let the script finish');
is($?, 512, 'the exit code should be nonzero');


ok(($pid = IPC::Open3::open3($in, $out, $err, $^X, @opts, $script, 'nonexistentfile')), 'run logfile-tail with nonexistent file');
ok(close $in, 'no input');
{
local $/ = undef;
$data = <$out>;
}
is($data, undef, '  stdout should have no output');
ok(close $out, '  closing stdout');
{
local $/ = undef;
$data = <$err>;
}
like($data, qr/^Error/, '  stderr should complain about file not existing');
ok(close $err, '  closing stderr');
ok(waitpid($pid, 0), 'let the script finish');
is($?, 768, 'the exit code should be nonzero');


ok(($pid = IPC::Open3::open3($in, $out, $err, $^X, @opts, $script, '--status=./nonexistent/dir', 't/file')), 'run logfile-tail with bad status but good file');
ok(close $in, 'no input');
{
local $/ = undef;
$data = <$out>;
}
is($data, undef, '  stdout should have no output');
ok(close $out, '  closing stdout');
{
local $/ = undef;
$data = <$err>;
}
like($data, qr/^Error/, '  stderr should complain about file not existing');
ok(close $err, '  closing stderr');
ok(waitpid($pid, 0), 'let the script finish');
is($?, 768, 'the exit code should be nonzero');


ok(open($pipe, '-|', $^X, @opts, $script, 't/file'), 'call the logfile-tail script on t/file');
is($data = scalar <$pipe>, "line 1: mali\350k\375 je\276e\350ek\n", 'read the first line');
is($data = scalar <$pipe>, "line 2: \276lu\273ou\350k\375 k\371\362\n", 'read the second line');
is($data = scalar <$pipe>, undef, 'no more data');
is(close($pipe), 1, 'close the pipe');
is($?, 0, 'the exit code should be zero');

append_to_file('t/file', 'append two more lines',
	'line 3', 'line 4');


ok(open($pipe, '-|', $^X, @opts, $script, 't/file'), 'call the logfile-tail script on t/file again, after two lines were appended');
is($data = scalar <$pipe>, "line 3\n", 'read the third line');
is($data = scalar <$pipe>, "line 4\n", 'read the fourth line');
is($data = scalar <$pipe>, undef, 'and that is it, no more data');
is(close($pipe), 1, 'close the pipe');
is($?, 0, 'the exit code should be zero');


local * TOUCH;
unlink 't/status-file2';
ok(open(TOUCH, '>', 't/status-file2'), 'create status file');
close TOUCH;

ok(open($pipe, '-|', $^X, @opts, $script, '--status=t/status-file2', 't/file'), 'call logfile-tail on t/file, now with status file');
is($data = scalar <$pipe>, "line 1: mali\350k\375 je\276e\350ek\n", 'read the first line');
is($data = scalar <$pipe>, "line 2: \276lu\273ou\350k\375 k\371\362\n", 'read the second line');
is($data = scalar <$pipe>, "line 3\n", 'read the third line');
is($data = scalar <$pipe>, "line 4\n", 'read the fourth line');
is($data = scalar <$pipe>, undef, 'fourth line was the last one');
is(close($pipe), 1, 'close the pipe');
is($?, 0, 'the exit code should be zero');

check_status_file('t/status-file2',
	"File [t/file] offset [60] checksum [ed51a8233c59ae97fecd83b625878a43a5c833982ee11e31e02873339f5c34cf]\n",
        'check that the offset stored is correct'
);


local * TOUCH;
unlink 't/status-file2';
ok(open(TOUCH, '>', 't/status-file2'), 'create status file');
close TOUCH;

my $cwd = Cwd::getcwd();
ok(open($pipe, '-|', $^X, @opts, $script, "--status=$cwd/t/status-file2", 't/file'), 'call logfile-tail on t/file, now with status file as absolute path');
is($data = scalar <$pipe>, "line 1: mali\350k\375 je\276e\350ek\n", 'read the first line');
is($data = scalar <$pipe>, "line 2: \276lu\273ou\350k\375 k\371\362\n", 'read the second line');
is($data = scalar <$pipe>, "line 3\n", 'read the third line');
is($data = scalar <$pipe>, "line 4\n", 'read the fourth line');
is($data = scalar <$pipe>, undef, 'fourth line was the last one');
is(close($pipe), 1, 'close the pipe');
is($?, 0, 'the exit code should be zero');

check_status_file('t/status-file2',
	"File [t/file] offset [60] checksum [ed51a8233c59ae97fecd83b625878a43a5c833982ee11e31e02873339f5c34cf]\n",
        'check that the offset stored is correct'
);

