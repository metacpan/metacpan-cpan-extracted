use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);

my $err = gensym;
my $pid = open3(my $in, my $out, $err, $^X, 'bin/jq-lite', '-n', '.');
close $in;

my $stdout = do { local $/; <$out> } // '';
my $stderr = do { local $/; <$err> } // '';

waitpid($pid, 0);

is($stdout, "null\n", 'null-input mode returns null by default');
like($stderr, qr/^\s*\z/, 'null-input mode does not emit warnings');

my $exit_code = $? >> 8;
is($exit_code, 0, 'process exits successfully when using --null-input');

done_testing;
