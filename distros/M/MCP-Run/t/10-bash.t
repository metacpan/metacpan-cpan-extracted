use strict;
use warnings;
use Test::More;
use Path::Tiny qw( tempdir );

use Time::HiRes qw( sleep time );

use MCP::Run::Bash;

# Event-driven waiting instead of fixed sleeps: a fixed pause is a guess about
# how long the machine takes, and loading Bash.pm in a fresh perl alone took
# 2.3s under load. Poll for the event itself, with a generous deadline that only
# a real failure ever reaches (karr #43).
sub wait_until {
  my ( $what, $deadline, $check ) = @_;
  my $end = time + $deadline;
  until ( $check->() ) {
    return 0 if time > $end;
    sleep 0.02;
  }
  return 1;
}

sub tick_size { my $f = shift; return -s "$f" // 0 }

# True while anything is left in the process group $pgid.
sub group_alive { my $pgid = shift; return kill 0, -$pgid }

# Run a snippet of Perl in a subprocess and return what it printed, or undef
# if the subprocess could not be started. The caller has to be a subprocess:
# a guard that goes missing in there would kill the test process itself
# instead of failing an assertion.
sub run_caller {
  my ( $code, @args ) = @_;

  my @inc = map { "-I$_" } grep { !ref } @INC;
  my $pid = open my $caller_out, '-|', $^X, @inc, '-e', $code, @args;
  return undef unless $pid;

  my $reported = do { local $/; <$caller_out> } // '';
  close $caller_out;
  return $reported;
}

# The identity defaults live on the class, not in bin/mcp-run-bash, so that
# library users of MCP::Run::Bash are not announced as MCP::Server's
# 'PerlServer' / '1.0.0' either. Asserting it here is what pins that
# placement — a version of the fix that only patched the bin script would
# still satisfy the stdio test in t/50-bash-bin.t, but not this one.
subtest 'default name and version identify the distribution' => sub {
  my $server = MCP::Run::Bash->new;
  is $server->name, 'mcp-run-bash', 'default name';
  is $server->version, $MCP::Run::Bash::VERSION, 'default version is the distribution version';
  isnt $server->version, '1.0.0', 'not the MCP::Server default';

  my $custom = MCP::Run::Bash->new(name => 'RunServer', version => '0.001');
  is $custom->name, 'RunServer', 'constructor still overrides name';
  is $custom->version, '0.001', 'constructor still overrides version';
};

subtest 'constructor registers run tool' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $tools  = $server->tools;
  is scalar(@$tools), 1, 'one tool registered';
  is $tools->[0]->name, 'run', 'tool name is run';

  my $schema = $tools->[0]->input_schema;
  is $schema->{type}, 'object', 'schema type is object';
  ok exists $schema->{properties}{command}, 'schema has command property';
  ok exists $schema->{properties}{working_directory}, 'schema has working_directory property';
  ok exists $schema->{properties}{timeout}, 'schema has timeout property';
  is_deeply $schema->{required}, ['command'], 'command is required';
};

subtest 'custom tool_name' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer', tool_name => 'exec');
  is $server->tools->[0]->name, 'exec', 'custom tool name';
};

subtest 'custom tool_description' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer', tool_description => 'Run stuff');
  is $server->tool_description, 'Run stuff', 'custom tool description';
};

subtest 'simple command execution' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $result = $server->execute('echo hello', undef, 10);
  is $result->{exit_code}, 0, 'exit code 0';
  is $result->{stdout}, 'hello', 'stdout captured';
  is $result->{stderr}, '', 'no stderr';
};

subtest 'stderr capture' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $result = $server->execute('echo err >&2', undef, 10);
  is $result->{exit_code}, 0, 'exit code 0';
  is $result->{stdout}, '', 'no stdout';
  is $result->{stderr}, 'err', 'stderr captured';
};

subtest 'non-zero exit code' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $result = $server->execute('exit 42', undef, 10);
  is $result->{exit_code}, 42, 'exit code 42';
};

subtest 'working_directory' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $result = $server->execute('pwd', '/tmp', 10);
  is $result->{exit_code}, 0, 'exit code 0';
  like $result->{stdout}, qr{^/tmp/?$}, 'ran in /tmp';
};

subtest 'server default working_directory' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer', working_directory => '/tmp');
  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'pwd'}, {});
  like $result->{content}[0]{text}, qr{/tmp}, 'uses server default working_directory';
};

subtest 'timeout' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $result = $server->execute('sleep 60', undef, 1);
  is $result->{exit_code}, 124, 'exit code 124 on timeout';
  ok defined $result->{error}, 'error message set';
  like $result->{error}, qr/timed out/i, 'error mentions timeout';
};

subtest 'allowed_commands: allowed' => sub {
  my $server = MCP::Run::Bash->new(
    name             => 'TestServer',
    allowed_commands => ['echo', 'pwd'],
  );
  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'echo ok'}, {});
  like $result->{content}[0]{text}, qr/Exit code: 0/, 'allowed command runs';
};

subtest 'allowed_commands: blocked' => sub {
  my $server = MCP::Run::Bash->new(
    name             => 'TestServer',
    allowed_commands => ['echo'],
  );
  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'rm -rf /'}, {});
  like $result->{content}[0]{text}, qr/Command not allowed: rm/, 'blocked command rejected';
  ok $result->{isError}, 'isError set for blocked command';
};

subtest 'format_result: success' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $tool   = $server->tools->[0];
  my $result = $server->format_result($tool, { exit_code => 0, stdout => 'hello', stderr => '' });
  like $result->{content}[0]{text}, qr/Exit code: 0/, 'contains exit code';
  like $result->{content}[0]{text}, qr/hello/, 'contains stdout';
  ok !$result->{isError}, 'isError is false for success';
};

subtest 'format_result: error' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $tool   = $server->tools->[0];
  my $result = $server->format_result($tool, { exit_code => 1, stdout => '', stderr => 'fail', error => 'boom' });
  like $result->{content}[0]{text}, qr/Exit code: 1/, 'contains exit code';
  like $result->{content}[0]{text}, qr/fail/, 'contains stderr';
  like $result->{content}[0]{text}, qr/boom/, 'contains error';
  ok $result->{isError}, 'isError is true for failure';
};

subtest 'validator: allowed' => sub {
  my $server = MCP::Run::Bash->new(
    name      => 'TestServer',
    validator => sub {
      my ($cmd, $dir) = @_;
      return 1 if $cmd =~ /^echo|^pwd/;
      return "blocked: $cmd";
    },
  );
  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'echo ok'}, {});
  like $result->{content}[0]{text}, qr/Exit code: 0/, 'allowed command runs';
};

subtest 'validator: denied with reason' => sub {
  my $server = MCP::Run::Bash->new(
    name      => 'TestServer',
    validator => sub {
      my ($cmd, $dir) = @_;
      return 1 if $cmd =~ /^echo|^pwd/;
      return "security policy forbids this";
    },
  );
  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'rm -rf /'}, {});
  like $result->{content}[0]{text}, qr/Command security policy forbids this/, 'blocked with reason';
  ok $result->{isError}, 'isError set for blocked command';
};

subtest 'validator: denied without reason' => sub {
  my $server = MCP::Run::Bash->new(
    name      => 'TestServer',
    validator => sub {
      my ($cmd, $dir) = @_;
      return 1 if $cmd =~ /^echo/;
      return;
    },
  );
  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'rm -rf /'}, {});
  like $result->{content}[0]{text}, qr/Command denied/, 'blocked without reason';
  ok $result->{isError}, 'isError set for blocked command';
};

# --- process handling regressions (karr #10) -------------------------------
#
# The four from the ticket, plus what fixing them turned up. Every one was
# measured against the code before the fix; the assertions below describe what
# execute() must do, not how it does it.

# $? >> 8 is 0 when the child was killed by a signal - the signal number sits
# in the low byte. A build killed by the OOM killer used to arrive as exit
# code 0 with truncated output, i.e. as a successful run.
subtest 'a signalled command reports 128 + signal number' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');

  my %expected = (HUP => 129, KILL => 137, TERM => 143);
  for my $signal (sort keys %expected) {
    my $result = $server->execute("kill -$signal \$\$; sleep 5", undef, 10);
    is $result->{exit_code}, $expected{$signal}, "SIG$signal reports $expected{$signal}";
  }

  is $server->execute('exit 42', undef, 10)->{exit_code}, 42, 'a normal exit code is still passed through';
  is $server->execute('echo hi', undef, 10)->{exit_code},  0,  'success is still 0';

  # The exit code only matters because the client acts on it.
  my $tool      = $server->tools->[0];
  my $formatted = $server->format_result($tool, $server->execute('kill -KILL $$; sleep 5', undef, 10));
  like $formatted->{content}[0]{text}, qr/Exit code: 137/, 'exit code 137 reaches the client';
  ok $formatted->{isError}, 'a signalled command is flagged as an error';
};

# The old code cleared the alarm, sent SIGTERM and then blocked in waitpid
# with nothing backing it up: a command that ignores SIGTERM kept the server
# hostage until it was done on its own (measured: 12s for a 2s timeout).
subtest 'a timeout escalates to SIGKILL when SIGTERM is ignored' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');

  my $start   = time;
  my $result  = $server->execute('trap "" TERM; sleep 30', undef, 1);
  my $elapsed = time - $start;

  is $result->{exit_code}, 124, 'still reported as a timeout';
  like $result->{error}, qr/timed out/i, 'error mentions the timeout';
  cmp_ok $elapsed, '<', 10, "returned after ${elapsed}s instead of sitting out the 30s command";
};

# Second way out of the timeout, same family: the read loop ends at EOF, so a
# command that closes its output and keeps running reached the waitpid with
# the alarm already cleared - and was reported as a plain success.
subtest 'a command that closes its output still times out' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');

  my $start   = time;
  my $result  = $server->execute('exec >/dev/null 2>&1; sleep 30', undef, 1);
  my $elapsed = time - $start;

  is $result->{exit_code}, 124, 'reported as a timeout, not as success';
  cmp_ok $elapsed, '<', 10, "returned after ${elapsed}s instead of the full 30s";
};

# kill 'TERM', $pid only reaches the bash, never what it started. The command
# gets its own process group now, so the timeout can signal the whole tree.
subtest 'a timeout kills the process group, not just bash' => sub {
  my $server  = MCP::Run::Bash->new(name => 'TestServer');
  my $dir     = tempdir(CLEANUP => 1);
  my $tick    = $dir->child('tick');
  my $pidfile = $dir->child('pid');

  # A grandchild that keeps working after bash is gone, and tells us so by
  # appending to a file we can watch.
  my $result = $server->execute(
    "( while :; do echo tick >> '$tick'; sleep 0.1; done ) & echo \$! > '$pidfile'; wait",
    undef, 3,
  );
  is $result->{exit_code}, 124, 'the command timed out';

  ok tick_size($tick), 'the grandchild was running while the command ran';
  my $pgid = $pidfile->exists ? $pidfile->slurp : '';
  chomp $pgid;
  # $! is the background subshell, not the group leader: watch that pid.
  ok $pgid =~ /^\d+$/ && wait_until( 'grandchild gone', 60, sub { !kill 0, $pgid } ),
    'the grandchild stopped working when the command timed out';
  my $ticks = tick_size($tick);
  sleep 0.3;
  is tick_size($tick), $ticks, 'and it stays stopped';

  # Do not leave a busy loop behind when this test fails.
  my $orphan = $pidfile->exists ? $pidfile->slurp : '';
  chomp $orphan;
  if ($orphan =~ /^\d+$/ && kill 0, $orphan) { kill 'KILL', -$orphan or kill 'KILL', $orphan }
};

# 0 is defined, so it survives the // in _handle_run, and alarm(0) cancels the
# alarm outright: a client could ask for timeout 0 and pin the server for as
# long as its command felt like running. Non-positive values fall back to the
# server default instead - unbounded is not on offer.
subtest 'a non-positive timeout falls back to the server default' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer', timeout => 1);

  for my $timeout (0, -5, 'nonsense', undef) {
    my $label   = defined $timeout ? "'$timeout'" : 'undef';
    my $start   = time;
    my $result  = $server->execute('sleep 30', undef, $timeout);
    my $elapsed = time - $start;
    is $result->{exit_code}, 124, "timeout $label falls back to the 1s server default";
    cmp_ok $elapsed, '<', 10, "timeout $label did not run unbounded (${elapsed}s)";
  }

  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'sleep 30', timeout => 0}, {});
  like $result->{content}[0]{text}, qr/Exit code: 124/, 'a timeout of 0 from the client is bounded too';

  # A server default that is itself unusable must not disable the alarm
  # either. Sitting that out would take 30s, so check the value directly.
  my $unusable = MCP::Run::Bash->new(name => 'TestServer', timeout => 0);
  is $unusable->_effective_timeout(0), 30, 'an unusable server default falls back to 30s';
  is $unusable->_effective_timeout(5), 5,  'a positive per-call timeout is used as given';
};

# Same hole as timeout 0, entered from the other side: Inf passes both
# looks_like_number and > 0, reaches alarm(), and comes back out as a negative
# argument - no alarm at all, plus a warning. From 2**32 up alarm() takes the
# value without a word and still sets nothing, because it counts in a C
# unsigned int. And alarm() counts whole seconds, so 0.5 would have meant
# alarm(0). Measured: 'sleep 8' ran to completion under a timeout of 1e400.
subtest 'a timeout alarm() cannot represent falls back as well' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer', timeout => 1);

  for my $timeout ('1e400', 2**40, 0.5) {
    my $start   = time;
    my $result  = $server->execute('sleep 30', undef, $timeout);
    my $elapsed = time - $start;
    is $result->{exit_code}, 124, "timeout '$timeout' is bounded by the 1s server default";
    cmp_ok $elapsed, '<', 10, "timeout '$timeout' did not run unbounded (${elapsed}s)";
  }

  # The rest of the range, without sitting out a timeout for every entry.
  my $server30 = MCP::Run::Bash->new(name => 'TestServer', timeout => 30);
  is $server30->_effective_timeout('1e400'),  30, 'Inf falls back';
  is $server30->_effective_timeout('-1e400'), 30, '-Inf falls back';
  is $server30->_effective_timeout('NaN'),    30, 'NaN falls back';
  is $server30->_effective_timeout(2**31),    30, 'one past what alarm() represents falls back';
  is $server30->_effective_timeout(2**32),    30, 'and so does the range where alarm() silently set nothing';
  is $server30->_effective_timeout(2**31 - 1), 2**31 - 1, 'the largest value alarm() still keeps is used as given';
  is $server30->_effective_timeout(0.5), 1,  'half a second becomes one - alarm(0) would switch the timeout off';
  is $server30->_effective_timeout(1.9), 1,  'fractions are truncated the way alarm() truncates them';
  is $server30->_effective_timeout(10),  10, 'a plain value is passed through untouched';
};

# The Inf case announced itself as 'alarm() with negative argument' - the kind
# of warning t/30-no-warnings.t exists for. A timeout the server cannot use is
# handled, not complained about.
subtest 'an unusable timeout produces no warnings' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer', timeout => 5);

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  $server->execute('echo quick', undef, $_)
    for '1e400', '-1e400', 'NaN', 2**40, 0.5, 'nonsense', 0, -5, undef;

  is_deeply \@warnings, [], 'nothing warned while running with unusable timeouts'
    or diag "warnings: @warnings";
};

# A signal handler in the embedding program interrupts the select in the read
# loop. can_read then returns empty, which the loop used to read as end of
# output: everything the command printed afterwards was dropped silently.
subtest 'a signal during the read loop does not truncate output' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');

  my $received = 0;
  local $SIG{USR1} = sub { $received++ };

  # The first sleep is what puts the parent inside select before the signal
  # arrives - without it the handler runs between reads and proves nothing.
  my $result = $server->execute(
    'echo first; sleep 1; kill -USR1 $PPID; sleep 1; echo second; echo third',
    undef, 20,
  );

  is $received, 1, 'the handler of the embedding program ran during the read loop';
  is $result->{exit_code}, 0, 'the command ran to completion';
  is $result->{stdout}, "first\nsecond\nthird", 'output produced after the signal is still captured';
};

# The command sits in its own process group now, so a kill aimed at the
# process running execute() no longer reaches it. execute() forwards the
# signal instead of leaving the command running unattended.
subtest 'terminating the caller takes the command with it' => sub {
  my $dir     = tempdir(CLEANUP => 1);
  my $tick    = $dir->child('tick');
  my $pidfile = $dir->child('pid');

  my $inner = "echo \$\$ > '$pidfile'; while :; do echo tick >> '$tick'; sleep 0.1; done";
  my $code  = "use MCP::Run::Bash; MCP::Run::Bash->new->execute(q{$inner}, undef, 120)";
  my @inc   = map { "-I$_" } grep { !ref } @INC;

  my $pid = open my $caller_out, '-|', $^X, @inc, '-e', $code;
  unless ($pid) {
    plan skip_all => "cannot fork a caller process: $!";
    return;
  }
  ok wait_until( 'command running', 60, sub { tick_size($tick) } ), 'the command is running';

  kill 'TERM', $pid;
  close $caller_out;    # reaps the caller

  my $orphan = $pidfile->exists ? $pidfile->slurp : '';
  chomp $orphan;
  my $pgid = $orphan =~ /^\d+$/ ? $orphan : 0;
  ok $pgid && wait_until( 'group gone', 60, sub { !group_alive($pgid) } ),
    'the command stopped when its caller was terminated';

  # Nothing is left in the group, so nothing can still be writing.
  my $ticks = tick_size($tick);
  sleep 0.3;
  is tick_size($tick), $ticks, 'and it stays stopped';

  $orphan = $pidfile->exists ? $pidfile->slurp : '';
  chomp $orphan;
  if ($orphan =~ /^\d+$/ && kill 0, $orphan) { kill 'KILL', -$orphan or kill 'KILL', $orphan }
};

# ... but forwarding must not take a signal away from a program that handles
# it itself - this is a library, and how a server shuts down is its own
# business. What is not the library's business to decide is that the command
# keeps running: the signal is chained to the program's own handler, and the
# command is stopped either way. Run in a subprocess: if the guard goes
# missing, the caller is killed by its own SIGTERM instead of reaching the
# print.
subtest 'a signal the caller handles itself stops the command and is chained' => sub {
  my $dir     = tempdir(CLEANUP => 1);
  my $pidfile = $dir->child('pid');

  my $code = <<'CALLER';
use MCP::Run::Bash;
my $handled = 0;
$SIG{TERM} = sub { $handled++ };
my $result = MCP::Run::Bash->new->execute($ARGV[0], undef, 20);
print "handled=$handled exit=$result->{exit_code} stdout=$result->{stdout}\n";
CALLER

  my $reported = run_caller($code, "echo \$\$ > '$pidfile'; kill -TERM \$PPID; sleep 1; echo done");
  plan skip_all => 'cannot fork a caller process' unless defined $reported;

  like $reported, qr/handled=1 /, "the caller's own TERM handler ran, chained after ours";
  like $reported, qr/exit=143 /, 'and the command was killed instead of left running';
  unlike $reported, qr/stdout=done/, 'the command did not run to the end';

  # The command is gone, and so is its process group - a signal that stops
  # the command must not leave the group behind.
  my $pgid = $pidfile->exists ? $pidfile->slurp : '';
  chomp $pgid;
  ok $pgid =~ /^\d+$/ && wait_until( 'group gone', 60, sub { !group_alive($pgid) } ),
    'no process group was left behind';

  my $orphan = $pidfile->exists ? $pidfile->slurp : '';
  chomp $orphan;
  if ($orphan =~ /^\d+$/ && kill 0, $orphan) { kill 'KILL', -$orphan or kill 'KILL', $orphan }
};

# An ignored signal stays ignored - in the program and in the command. The
# program asked for the signal to have no effect on it, and the command
# inherits the disposition across the exec, so taking the signal over would
# only make program and command disagree about it. This is the one case in
# which a command can outlive the signal aimed at the program running it,
# and it is the behaviour the module had before handlers were chained.
subtest 'a signal the caller ignores is left alone' => sub {
  my $code = <<'CALLER';
use MCP::Run::Bash;
$SIG{TERM} = 'IGNORE';
my $result = MCP::Run::Bash->new->execute($ARGV[0], undef, 20);
print "alive=1 exit=$result->{exit_code} stdout=$result->{stdout}\n";
CALLER

  my $reported = run_caller($code, 'kill -TERM $PPID; sleep 1; echo done');
  plan skip_all => 'cannot fork a caller process' unless defined $reported;

  like $reported, qr/alive=1 /, 'the caller ignored the signal and is still running';
  like $reported, qr/exit=0 /, 'and the command was left running, as before';
  like $reported, qr/stdout=done/, 'the ignored signal did not stop it';
};

done_testing;
