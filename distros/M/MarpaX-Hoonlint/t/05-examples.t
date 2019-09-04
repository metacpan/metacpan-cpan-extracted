# Test of hoonlint utility

use 5.010;
use strict;
use warnings;

use Data::Dumper;
use English qw( -no_match_vars );

use Test::More tests => 12;

use Test::Differences;
use IPC::Cmd qw[run_forked];

sub slurp {
    my ($fileName) = @_;
    local $RS = undef;
    my $fh;
    open $fh, q{<}, $fileName or die "Cannot open $fileName";
    my $file = <$fh>;
    close $fh;
    return \$file;
}

my @tests = (
    ['hoons/examples/fizzbuzz.hoon', 't/examples.d/fizzbuzz.lint.out', '--sup=suppressions/examples.suppressions'],
    ['hoons/examples/sieve_b.hoon', 't/examples.d/sieve_b.lint.out', '--sup=suppressions/examples.suppressions'],
    ['hoons/examples/sieve_k.hoon', 't/examples.d/sieve_k.lint.out', '--sup=suppressions/examples.suppressions'],
    ['hoons/examples/toe.hoon', 't/examples.d/toe.lint.out', '--sup=suppressions/examples.suppressions'],
);

local $Data::Dumper::Deepcopy    = 1;
local $Data::Dumper::Terse    = 1;

my @Iflags = map { '-I' . $_ } @INC;


for my $testData (@tests) {

    my ($stdinName, $stdoutName, @options) = @{$testData};

    my $cmd = [ $^X, @Iflags, './hoonlint', @options, $stdinName ];

    my @stdout       = ();
    my $gatherStdout = sub {
        push @stdout, @_;
    };

    my @stderr       = ();
    my $gatherStderr = sub {
        push @stderr, @_;
    };

    my $pExpectedStdout = $stdoutName ? slurp($stdoutName) : \q{};

    my $result = run_forked(
        $cmd,
        {
            child_stdin    => '',
            stdout_handler => $gatherStdout,
            stderr_handler => $gatherStderr,
            discard_output => 1,
        }
    );

    my $exitCode = $result->{'exit_code'};
    Test::More::ok( $exitCode eq 0, "exit code for $stdinName.pl is $exitCode" );

    my $errMsg = $result->{'err_msg'};
    Test::More::diag($errMsg) if $errMsg;

    my $stderr = join q{}, @stderr;
    Test::More::diag($stderr) if $stderr;
    Test::More::ok( $stderr eq q{}, "STDERR for $stdinName" );

    my $stdout = join q{}, @stdout;
    eq_or_diff( $stdout, ${$pExpectedStdout}, "STDOUT for $stdinName" );
  }

# vim: expandtab shiftwidth=4:
