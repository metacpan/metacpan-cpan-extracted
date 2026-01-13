#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;
use Test2::V0;

use Cwd;
use FindBin    qw( $RealBin );
use File::Spec ();
my $lib_path;

BEGIN {
    $lib_path = File::Spec->catdir( ( $RealBin =~ /(.+)/msx )[0], q{.}, 'lib' );
}
use lib "$lib_path";

use Test2::Deny::Platform::DOSOrDerivative;

use Test::Script 1.28;

subtest 'Script compiles' => sub {
    script_compiles('bin/envdot');

    done_testing;
};

subtest 'Script runs --version' => sub {
    script_runs( [ 'bin/envdot', '--version', ] );
    script_runs( [ 'bin/envdot', '--version', ], { interpreter_options => ['-T'], }, 'Runs with taint check enabled' );

    my $stdout;
    script_runs( [ 'bin/envdot', '--version', ], { stdout => \$stdout, }, 'Verify output' );
    like( ( split qr/\n/msx, $stdout )[0], qr/^ bin [\/\\] envdot (\s version \s .* |) $/msx,      'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[1], qr/^ [(] Getopt::Long::GetOptions [[:space:]]{1,} /msx, 'Correct stdout' );

    done_testing;
};

subtest 'Script runs --dotenv' => sub {
    script_runs( [ 'bin/envdot', '--dotenv', 't/envdot-script-first.env', ] );
    script_runs(
        [ 'bin/envdot', '--dotenv', 't/envdot-script-first.env', ],
        { interpreter_options => ['-T'], },
        'Runs with taint check enabled'
    );

    my $stdout;
    my $stdout_result = <<"EOF";
ENVDOT_SCRIPT_TEST_1='1'; export ENVDOT_SCRIPT_TEST_1
ENVDOT_SCRIPT_TEST_2='two'; export ENVDOT_SCRIPT_TEST_2
ENVDOT_SCRIPT_COMMON='first'; export ENVDOT_SCRIPT_COMMON
EOF
    script_runs( [ 'bin/envdot', '--dotenv', 't/envdot-script-first.env', ], { stdout => \$stdout, }, 'Verify output' );
    is( $stdout, $stdout_result, 'Correct stdout' );

    done_testing;
};

subtest 'Script runs ENVDOT_FILEPATHS=path' => sub {
    my $path = File::Spec->rel2abs( File::Spec->catfile( File::Spec->curdir(), 't', 'envdot-script-first.env' ) );

    local %ENV = ( %ENV, ENVDOT_FILEPATHS => $path );

    # for my $e (keys %ENV) { warn "$e: $ENV{$e}\n"; }
    script_runs( [ 'bin/envdot', ] );
    script_runs( [ 'bin/envdot', ], { interpreter_options => ['-T'], }, 'Runs with taint check enabled' );

    my $stdout;
    my $stdout_result = <<"EOF";
ENVDOT_SCRIPT_TEST_1='1'; export ENVDOT_SCRIPT_TEST_1
ENVDOT_SCRIPT_TEST_2='two'; export ENVDOT_SCRIPT_TEST_2
ENVDOT_SCRIPT_COMMON='first'; export ENVDOT_SCRIPT_COMMON
EOF
    script_runs( [ 'bin/envdot', ], { stdout => \$stdout, }, 'Verify output' );
    is( $stdout, $stdout_result, 'Correct stdout' );

    done_testing;
};

subtest 'Script runs ENVDOT_FILEPATHS=path_first:path_second' => sub {
    my $path1 = File::Spec->rel2abs( File::Spec->catfile( File::Spec->curdir(), 't', 'envdot-script-first.env' ) );
    my $path2 = File::Spec->rel2abs( File::Spec->catfile( File::Spec->curdir(), 't', 'envdot-script-second.env' ) );

    local %ENV = ( ENVDOT_FILEPATHS => "${path2}:${path1}" );
    script_runs( [ 'bin/envdot', ] );
    script_runs( [ 'bin/envdot', ], { interpreter_options => ['-T'], }, 'Runs with taint check enabled' );

    my $stdout;
    my $stdout_result = <<"EOF";
ENVDOT_SCRIPT_TEST_1='1'; export ENVDOT_SCRIPT_TEST_1
ENVDOT_SCRIPT_TEST_2='two'; export ENVDOT_SCRIPT_TEST_2
ENVDOT_SCRIPT_COMMON='first'; export ENVDOT_SCRIPT_COMMON
ENVDOT_SCRIPT_TEST_3='03'; export ENVDOT_SCRIPT_TEST_3
ENVDOT_SCRIPT_TEST_4='4.0'; export ENVDOT_SCRIPT_TEST_4
ENVDOT_SCRIPT_COMMON='second'; export ENVDOT_SCRIPT_COMMON
EOF
    script_runs( [ 'bin/envdot', ], { stdout => \$stdout, }, 'Verify output' );
    is( $stdout, $stdout_result, 'Correct stdout' );

    done_testing;
};

subtest 'Script runs ENVDOT_FILEPATHS=path_second:path_first' => sub {
    my $path1 = File::Spec->rel2abs( File::Spec->catfile( File::Spec->curdir(), 't', 'envdot-script-first.env' ) );
    my $path2 = File::Spec->rel2abs( File::Spec->catfile( File::Spec->curdir(), 't', 'envdot-script-second.env' ) );

    local %ENV = ( ENVDOT_FILEPATHS => "${path1}:${path2}" );
    script_runs( [ 'bin/envdot', ] );
    script_runs( [ 'bin/envdot', ], { interpreter_options => ['-T'], }, 'Runs with taint check enabled' );

    my $stdout;
    my $stdout_result = <<"EOF";
ENVDOT_SCRIPT_TEST_3='03'; export ENVDOT_SCRIPT_TEST_3
ENVDOT_SCRIPT_TEST_4='4.0'; export ENVDOT_SCRIPT_TEST_4
ENVDOT_SCRIPT_COMMON='second'; export ENVDOT_SCRIPT_COMMON
ENVDOT_SCRIPT_TEST_1='1'; export ENVDOT_SCRIPT_TEST_1
ENVDOT_SCRIPT_TEST_2='two'; export ENVDOT_SCRIPT_TEST_2
ENVDOT_SCRIPT_COMMON='first'; export ENVDOT_SCRIPT_COMMON
EOF
    script_runs( [ 'bin/envdot', ], { stdout => \$stdout, }, 'Verify output' );
    is( $stdout, $stdout_result, 'Correct stdout' );

    done_testing;
};

subtest 'Script fails due to faulty option' => sub {
    my $file     = 't/envdot-script-third.env';
    my $filepath = File::Spec->rel2abs($file);
    script_fails( [ 'bin/envdot', '--dotenv', $file, ], { exit => 22, }, 'Fails because of faulty option' );

    ## no critic (RegularExpressions::ProhibitComplexRegexes)
    script_stderr_like(
        qr{^ Error: \s Unknown \s envdot \s option: \s 'read:faulty_option' \s line \s 3 \s file \s '$filepath' $}msx,
        'Fails with correct output' );

    done_testing;
};

subtest 'Script fails due to missing dotenv file' => sub {
    my $file     = 't/envdot-script-not-existing.env';
    my $filepath = File::Spec->rel2abs($file);
    script_fails( [ 'bin/envdot', '--dotenv', $file, ], { exit => 2, }, 'Fails because of missing dotenv file' );

    script_stderr_like( qr{^ Error: \s File \s not \s found: \s '$file' $}msx, 'Fails with correct output' );

    done_testing;
};

done_testing;
