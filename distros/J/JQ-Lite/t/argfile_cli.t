use strict;
use warnings;
use Test::More;
use IPC::Open3;
use File::Temp qw(tempfile);
use Symbol qw(gensym);

my ($fh, $json_path) = tempfile();
print {$fh} '{"name":"Alice","tags":["x","y"]}';
close $fh;

my $err = gensym;
my $pid = open3(my $in, my $out, $err, $^X, 'bin/jq-lite', '--argfile', 'cfg', $json_path, '-n', '$cfg.tags[]');
close $in;

my $stdout = do { local $/; <$out> } // '';
my $stderr = do { local $/; <$err> } // '';
waitpid($pid, 0);
my $exit_code = $? >> 8;

is($exit_code, 0, '--argfile accepts valid JSON files');
like($stdout, qr/^"x"\n"y"\n/, 'JSON values from file are available inside queries');
like($stderr, qr/^\s*\z/, 'no warnings emitted for valid --argfile input');

my ($bad_fh, $bad_path) = tempfile();
print {$bad_fh} '{invalid}';
close $bad_fh;

my $bad_err = gensym;
my $bad_pid = open3(my $bad_in, my $bad_out, $bad_err, $^X, 'bin/jq-lite', '--argfile', 'cfg', $bad_path, '-n', '$cfg');
close $bad_in;

my $bad_stdout = do { local $/; <$bad_out> } // '';
my $bad_stderr = do { local $/; <$bad_err> } // '';
waitpid($bad_pid, 0);
my $bad_exit = $? >> 8;

is($bad_exit, 5, 'invalid --argfile input exits with usage code');
like($bad_stderr, qr/^\[USAGE\]\s*invalid JSON in --argfile cfg/i, 'error message is surfaced for invalid JSON');
unlike($bad_stderr, qr/Unknown option\(s\)/i, 'no secondary unknown option errors are emitted');
is($bad_stdout, '', 'no output is produced when --argfile fails');

my $missing_err = gensym;
my $missing_pid = open3(my $missing_in, my $missing_out, $missing_err, $^X, 'bin/jq-lite', '--argfile', 'cfg', 'no-such.json', '-n', '$cfg');
close $missing_in;

my $missing_stdout = do { local $/; <$missing_out> } // '';
my $missing_stderr = do { local $/; <$missing_err> } // '';
waitpid($missing_pid, 0);
my $missing_exit = $? >> 8;

is($missing_exit, 5, 'missing --argfile input exits with usage code');
like($missing_stderr, qr/^\[USAGE\]\s*Cannot open file 'no-such\.json' for --argfile cfg:/, 'missing file uses usage prefix and message');
is($missing_stdout, '', 'no output is produced when --argfile file is missing');

unlink $json_path;
unlink $bad_path;

done_testing;
