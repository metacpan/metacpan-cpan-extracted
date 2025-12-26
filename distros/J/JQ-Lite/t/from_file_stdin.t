use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);
use File::Spec;
use Cwd qw(abs_path);
use FindBin;

my $exe = abs_path(File::Spec->catfile($FindBin::Bin, '..', 'bin', 'jq-lite'));

sub run_cli {
    my ($input, @args) = @_;
    local $SIG{PIPE} = 'IGNORE';
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, $^X, $exe, @args);
    if (defined $input) {
        print {$in} $input;
    }
    close $in;

    my $stdout = do { local $/; <$out> } // '';
    my $stderr = do { local $/; <$err> } // '';
    waitpid($pid, 0);
    my $exit = $? >> 8;
    return ($stdout, $stderr, $exit);
}

subtest 'query from STDIN with --null-input succeeds' => sub {
    my ($stdout, $stderr, $exit) = run_cli("[1]\n", '-n', '--from-file', '-');
    is($stderr, '', 'no stderr for stdin query');
    is($exit, 0, 'process exits successfully');
    is($stdout, "[\n   1\n]\n", 'query read from STDIN emits expected JSON');
};

subtest 'query from STDIN without input file errors' => sub {
    my ($stdout, $stderr, $exit) = run_cli(".users\n", '--from-file', '-');
    is($stdout, '', 'no stdout when query fails');
    like(
        $stderr,
        qr/^\[USAGE\]\s*Cannot use --from-file - when reading JSON from STDIN\. Provide input file or use --null-input\./,
        'prints helpful error when both query and JSON use STDIN'
    );
    is($exit, 5, 'usage exit code returned');
};

DONE_TESTING:
done_testing;
