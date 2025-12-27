use strict;
use warnings;

use IPC::Open3;
use Symbol qw(gensym);
use File::Temp qw(tempfile);
use Test::More;

my ($fh, $filename) = tempfile();
print {$fh} "alpha\nbeta\n";
close $fh;

my $err = gensym;
my $pid = open3(my $in, my $out, $err, $^X, 'bin/jq-lite', '--rawfile', 'doc', $filename, '-n', '$doc | split("\\n") | length');
close $in;

my $stdout = do { local $/; <$out> } // '';
my $stderr = do { local $/; <$err> } // '';
waitpid($pid, 0);
my $exit_code = $? >> 8;

is($exit_code, 0, '--rawfile accepts an existing file');
is($stdout, "3\n", 'rawfile contents are exposed as a single string variable');
like($stderr, qr/^\s*\z/, 'no warnings emitted for valid --rawfile usage');

my $missing_err = gensym;
my $missing_pid = open3(my $missing_in, my $missing_out, $missing_err, $^X, 'bin/jq-lite', '--rawfile', 'doc', 'nonexistent.raw', '-n', '$doc');
close $missing_in;

my $missing_stdout = do { local $/; <$missing_out> } // '';
my $missing_stderr = do { local $/; <$missing_err> } // '';
waitpid($missing_pid, 0);
my $missing_exit = $? >> 8;

is($missing_exit, 5, '--rawfile exits with usage code when the file cannot be opened');
like($missing_stderr, qr/^\[USAGE\]\s*Cannot open file 'nonexistent\.raw'/i, 'error message includes the usage prefix and filename');
is($missing_stdout, '', 'no output is produced when --rawfile fails');

done_testing;
