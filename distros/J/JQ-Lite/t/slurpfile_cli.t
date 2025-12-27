use strict;
use warnings;

use File::Temp qw(tempfile);
use IPC::Open3;
use JSON::PP;
use Symbol qw(gensym);
use Test::More;

my ($cfg_fh, $cfg_path) = tempfile();
print {$cfg_fh} "{\"a\":1}\n";
close $cfg_fh;

my $err = gensym;
my $pid = open3(my $in, my $out, $err, $^X, 'bin/jq-lite', '--slurpfile', 'cfg', $cfg_path, '. + $cfg[0]');
print {$in} "{\"b\":2}\n";
close $in;

my $stdout = do { local $/; <$out> } // '';
my $stderr = do { local $/; <$err> } // '';
waitpid($pid, 0);
my $exit_code = $? >> 8;

is($exit_code, 0, '--slurpfile accepts valid JSON files');
my $decoded = JSON::PP->new->decode($stdout);
is_deeply($decoded, { a => 1, b => 2 }, 'slurpfile makes decoded JSON available inside queries');
like($stderr, qr/^\s*\z/, 'no warnings emitted for valid --slurpfile usage');

my $missing_query_err = gensym;
my $missing_query_pid = open3(my $missing_query_in, my $missing_query_out, $missing_query_err, $^X, 'bin/jq-lite', '--slurpfile', 'cfg', '.');
close $missing_query_in;

my $missing_query_stdout = do { local $/; <$missing_query_out> } // '';
my $missing_query_stderr = do { local $/; <$missing_query_err> } // '';
waitpid($missing_query_pid, 0);
my $missing_query_exit = $? >> 8;

is($missing_query_exit, 5, '--slurpfile without a file path produces a usage error instead of help');
like($missing_query_stderr, qr/^\[USAGE\]--slurpfile requires a file path/i, 'missing slurpfile file path is reported');
is($missing_query_stdout, '', 'no stdout is produced when filter is missing');

my $missing_err = gensym;
my $missing_pid = open3(my $missing_in, my $missing_out, $missing_err, $^X, 'bin/jq-lite', '--slurpfile', 'cfg', 'missing.json', '.');
close $missing_in;

my $missing_stdout = do { local $/; <$missing_out> } // '';
my $missing_stderr = do { local $/; <$missing_err> } // '';
waitpid($missing_pid, 0);
my $missing_exit = $? >> 8;

is($missing_exit, 5, '--slurpfile exits with usage code when file is missing');
like($missing_stderr, qr/^\[USAGE\]cannot read file: missing\.json/i, 'missing files report usage errors');
is($missing_stdout, '', 'no output is produced when slurpfile is missing');

my ($bad_fh, $bad_path) = tempfile();
print {$bad_fh} "{invalid}\n";
close $bad_fh;

my $bad_err = gensym;
my $bad_pid = open3(my $bad_in, my $bad_out, $bad_err, $^X, 'bin/jq-lite', '--slurpfile', 'cfg', $bad_path, '.');
close $bad_in;

my $bad_stdout = do { local $/; <$bad_out> } // '';
my $bad_stderr = do { local $/; <$bad_err> } // '';
waitpid($bad_pid, 0);
my $bad_exit = $? >> 8;

is($bad_exit, 5, '--slurpfile exits with usage code when JSON is invalid');
like($bad_stderr, qr/^\[USAGE\]invalid JSON in slurpfile cfg/i, 'invalid JSON reports usage errors');
is($bad_stdout, '', 'no output is produced when slurpfile JSON is invalid');

done_testing;
