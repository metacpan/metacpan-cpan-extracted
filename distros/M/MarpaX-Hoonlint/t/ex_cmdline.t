# Test of hoonlint utility

use 5.010;
use strict;
use warnings;

use Data::Dumper;
use English qw( -no_match_vars );
use IPC::Cmd qw[run_forked];
use Test::More ( import => [] );

if (IPC::Cmd->can_use_run_forked()) {
    Test::More::plan tests => 3;
}
else {
    Test::More::plan skip_all => 'Cannot call run_forked()';
}

use Test::Differences;

sub slurp {
    my ($fileName) = @_;
    local $RS = undef;
    my $fh;
    open $fh, q{<}, $fileName or die "Cannot open $fileName";
    my $file = <$fh>;
    close $fh;
    return \$file;
}

local $Data::Dumper::Deepcopy    = 1;
local $Data::Dumper::Terse    = 1;

my @Iflags = map { '-I' . $_ } @INC;


{

    my $cmd = [ $^X, @Iflags, './hoonlint',
        '--sup=suppressions/examples.suppressions',
        'hoons/examples/fizzbuzz.hoon',
        'hoons/examples/sieve_b.hoon',
        'hoons/examples/sieve_k.hoon',
        'hoons/examples/toe.hoon',
    ];

    my @stdout       = ();
    my $gatherStdout = sub {
        push @stdout, @_;
    };

    my @stderr       = ();
    my $gatherStderr = sub {
        push @stderr, @_;
    };

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
    Test::More::ok( $exitCode eq 0, "exit code is $exitCode" );

    my $errMsg = $result->{'err_msg'};
    Test::More::diag($errMsg) if $errMsg;

    my $stderr = join q{}, @stderr;
    Test::More::diag($stderr) if $stderr;
    Test::More::ok( $stderr eq q{}, "STDERR" );

    my $stdout = join q{}, @stdout;
    eq_or_diff( $stdout, '', "STDOUT" );
  }

# vim: expandtab shiftwidth=4:
