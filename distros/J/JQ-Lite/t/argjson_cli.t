use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);

my $err = gensym;
my $pid = open3(my $in, my $out, $err, $^X, 'bin/jq-lite', '--argjson', 'cfg', '{"name":"Alice","tags":["x","y"]}', '-n', '$cfg.tags[]');
close $in;

my $stdout = do { local $/; <$out> } // '';
my $stderr = do { local $/; <$err> } // '';
waitpid($pid, 0);
my $exit_code = $? >> 8;

is($exit_code, 0, '--argjson accepts valid JSON values');
is($stdout, "\"x\"\n\"y\"\n", 'JSON values are available inside queries');
like($stderr, qr/^\s*\z/, 'no warnings emitted for valid --argjson input');

my $bad_err = gensym;
my $bad_pid = open3(my $bad_in, my $bad_out, $bad_err, $^X, 'bin/jq-lite', '--argjson', 'cfg', '{invalid}', '-n', '$cfg');
close $bad_in;

my $bad_stdout = do { local $/; <$bad_out> } // '';
my $bad_stderr = do { local $/; <$bad_err> } // '';
waitpid($bad_pid, 0);
my $bad_exit = $? >> 8;

is($bad_exit, 2, 'invalid --argjson input exits with code 2');
like($bad_stderr, qr/Failed to parse JSON for --argjson cfg/i, 'error message is surfaced for invalid JSON');
unlike($bad_stderr, qr/Unknown option\(s\)/i, 'no secondary unknown option errors are emitted');
is($bad_stdout, '', 'no output is produced when --argjson fails');

done_testing;
