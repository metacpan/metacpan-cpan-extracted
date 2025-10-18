use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);

sub run_cli {
    my (%opts) = @_;
    my @cmd = ($^X, 'bin/jq-lite', @{ $opts{args} // [] });

    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, @cmd);

    if (defined $opts{stdin}) {
        print {$in} $opts{stdin};
    }
    close $in;

    my $stdout = do { local $/; <$out> } // '';
    my $stderr = do { local $/; <$err> } // '';

    waitpid($pid, 0);
    my $exit_code = $? >> 8;

    return ($stdout, $stderr, $exit_code);
}

my ($stdout, $stderr, $exit) = run_cli(
    args  => [ '-c', '-s', '.' ],
    stdin => "{\"name\":\"Alice\"}\n{\"name\":\"Bob\"}\n",
);

is($stdout, "[{\"name\":\"Alice\"},{\"name\":\"Bob\"}]\n", '--slurp aggregates multiple JSON documents');
like($stderr, qr/^\s*\z/, 'no warnings emitted when slurping multiple documents');
is($exit, 0, 'process exits successfully when slurping multiple documents');

($stdout, $stderr, $exit) = run_cli(
    args  => [ '-c', '-s', '.' ],
    stdin => "{\"name\":\"Carol\"}\n",
);

is($stdout, "[{\"name\":\"Carol\"}]\n", '--slurp wraps a single JSON document in an array');
like($stderr, qr/^\s*\z/, 'no warnings emitted when slurping a single document');
is($exit, 0, 'process exits successfully when slurping a single document');

($stdout, $stderr, $exit) = run_cli(
    args => [ '-c', '-s', '-n', '.' ],
);

is($stdout, "[]\n", '--slurp with --null-input starts from an empty array');
like($stderr, qr/^\s*\z/, 'no warnings emitted when combining --slurp with --null-input');
is($exit, 0, 'process exits successfully when slurping null input');

done_testing;
