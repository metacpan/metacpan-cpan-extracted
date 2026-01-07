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
    args  => [ '-R', '-c', '.' ],
    stdin => "foo\nbar\n",
);

is($stdout, "\"foo\"\n\"bar\"\n", '--raw-input processes each line as a separate string');
like($stderr, qr/^\s*\z/, 'no warnings emitted when reading raw lines');
is($exit, 0, 'process exits successfully for raw line input');

($stdout, $stderr, $exit) = run_cli(
    args  => [ '-R', '-s', '-c', '.' ],
    stdin => "alpha\nbeta\n",
);

is($stdout, "\"alpha\\nbeta\\n\"\n", '--raw-input with --slurp combines input into a single string');
like($stderr, qr/^\s*\z/, 'no warnings emitted when slurping raw text');
is($exit, 0, 'process exits successfully for slurped raw text');

($stdout, $stderr, $exit) = run_cli(
    args  => [ '-R', '-c', '.', 'nonexistent.json' ],
);

like($stderr, qr/No such file or directory|Cannot open file/, 'error surfaced when file is missing under --raw-input');
ok($exit != 0, 'nonexistent file under raw input causes non-zero exit');

($stdout, $stderr, $exit) = run_cli(
    args => [ '-R' ],
);

is($stdout, '', 'no output is produced when --raw-input is provided without a query');
like(
    $stderr,
    qr/^\[USAGE\]--raw-input requires a query when not using --slurp\./,
    'usage error is raised when --raw-input lacks a query'
);
is($exit, 5, '--raw-input without a query exits with usage code');

($stdout, $stderr, $exit) = run_cli(
    args => [ '-R', '-s' ],
);

is($stdout, '', 'no output is produced when --raw-input and --slurp are used without a query');
like(
    $stderr,
    qr/^\[USAGE\]--raw-input requires a query when used with --slurp\./,
    'usage error is raised when --raw-input --slurp lacks a query'
);
is($exit, 5, '--raw-input --slurp without a query exits with usage code');

done_testing;
