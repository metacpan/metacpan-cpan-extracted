#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;
use Cwd;
use File::Spec;
use Test2::V0;
use Test::Script;

subtest 'Script compiles' => sub {
    script_compiles('script/envdot');

    done_testing;
};

subtest 'Script runs --version' => sub {
    script_runs( [ 'script/envdot', '--version', ] );
    script_runs( [ 'script/envdot', '--version', ], { interpreter_options => ['-T'], }, 'Runs with taint check enabled' );

    my $stdout;
    script_runs( [ 'script/envdot', '--version', ], { stdout => \$stdout, }, 'Verify output' );
    like( ( split qr/\n/msx, $stdout )[0], qr/^ script [\/\\] envdot (\s version \s .* |) $/msx,   'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[1], qr/^ [(] Getopt::Long::GetOptions [[:space:]]{1,} /msx, 'Correct stdout' );

    done_testing;
};

subtest 'Script runs --dotenv' => sub {
    script_runs( [ 'script/envdot', '--dotenv', 't/envdot-script-first.env', ] );
    script_runs(
        [ 'script/envdot', '--dotenv', 't/envdot-script-first.env', ],
        { interpreter_options => ['-T'], },
        'Runs with taint check enabled'
    );

    my $stdout;
    my $stdout_result = <<"EOF";
ENVDOT_SCRIPT_TEST_1='1'; export ENVDOT_SCRIPT_TEST_1
ENVDOT_SCRIPT_TEST_2='two'; export ENVDOT_SCRIPT_TEST_2
ENVDOT_SCRIPT_COMMON='first'; export ENVDOT_SCRIPT_COMMON
EOF
    script_runs( [ 'script/envdot', '--dotenv', 't/envdot-script-first.env', ], { stdout => \$stdout, }, 'Verify output' );
    is( $stdout, $stdout_result, 'Correct stdout' );

    done_testing;
};

subtest 'Script runs ENVDOT_FILEPATHS=path' => sub {
    my $path = File::Spec->rel2abs( File::Spec->catfile( File::Spec->curdir(), 't', 'envdot-script-first.env' ) );

    local %ENV = ( ENVDOT_FILEPATHS => $path );
    script_runs( [ 'script/envdot', ] );
    script_runs( [ 'script/envdot', ], { interpreter_options => ['-T'], }, 'Runs with taint check enabled' );

    my $stdout;
    my $stdout_result = <<"EOF";
ENVDOT_SCRIPT_TEST_1='1'; export ENVDOT_SCRIPT_TEST_1
ENVDOT_SCRIPT_TEST_2='two'; export ENVDOT_SCRIPT_TEST_2
ENVDOT_SCRIPT_COMMON='first'; export ENVDOT_SCRIPT_COMMON
EOF
    script_runs( [ 'script/envdot', ], { stdout => \$stdout, }, 'Verify output' );
    is( $stdout, $stdout_result, 'Correct stdout' );

    done_testing;
};

subtest 'Script runs ENVDOT_FILEPATHS=path_first:path_second' => sub {
    my $path1 = File::Spec->rel2abs( File::Spec->catfile( File::Spec->curdir(), 't', 'envdot-script-first.env' ) );
    my $path2 = File::Spec->rel2abs( File::Spec->catfile( File::Spec->curdir(), 't', 'envdot-script-second.env' ) );

    local %ENV = ( ENVDOT_FILEPATHS => "${path2}:${path1}" );
    script_runs( [ 'script/envdot', ] );
    script_runs( [ 'script/envdot', ], { interpreter_options => ['-T'], }, 'Runs with taint check enabled' );

    my $stdout;
    my $stdout_result = <<"EOF";
ENVDOT_SCRIPT_TEST_1='1'; export ENVDOT_SCRIPT_TEST_1
ENVDOT_SCRIPT_TEST_2='two'; export ENVDOT_SCRIPT_TEST_2
ENVDOT_SCRIPT_COMMON='first'; export ENVDOT_SCRIPT_COMMON
ENVDOT_SCRIPT_TEST_3='03'; export ENVDOT_SCRIPT_TEST_3
ENVDOT_SCRIPT_TEST_4='4.0'; export ENVDOT_SCRIPT_TEST_4
ENVDOT_SCRIPT_COMMON='second'; export ENVDOT_SCRIPT_COMMON
EOF
    script_runs( [ 'script/envdot', ], { stdout => \$stdout, }, 'Verify output' );
    is( $stdout, $stdout_result, 'Correct stdout' );

    done_testing;
};

subtest 'Script runs ENVDOT_FILEPATHS=path_second:path_first' => sub {
    my $path1 = File::Spec->rel2abs( File::Spec->catfile( File::Spec->curdir(), 't', 'envdot-script-first.env' ) );
    my $path2 = File::Spec->rel2abs( File::Spec->catfile( File::Spec->curdir(), 't', 'envdot-script-second.env' ) );

    local %ENV = ( ENVDOT_FILEPATHS => "${path1}:${path2}" );
    script_runs( [ 'script/envdot', ] );
    script_runs( [ 'script/envdot', ], { interpreter_options => ['-T'], }, 'Runs with taint check enabled' );

    my $stdout;
    my $stdout_result = <<"EOF";
ENVDOT_SCRIPT_TEST_3='03'; export ENVDOT_SCRIPT_TEST_3
ENVDOT_SCRIPT_TEST_4='4.0'; export ENVDOT_SCRIPT_TEST_4
ENVDOT_SCRIPT_COMMON='second'; export ENVDOT_SCRIPT_COMMON
ENVDOT_SCRIPT_TEST_1='1'; export ENVDOT_SCRIPT_TEST_1
ENVDOT_SCRIPT_TEST_2='two'; export ENVDOT_SCRIPT_TEST_2
ENVDOT_SCRIPT_COMMON='first'; export ENVDOT_SCRIPT_COMMON
EOF
    script_runs( [ 'script/envdot', ], { stdout => \$stdout, }, 'Verify output' );
    is( $stdout, $stdout_result, 'Correct stdout' );

    done_testing;
};

# First thing change dir!
# my ($path_first, $path_second, $path_third);
# my ($path_interpolation, $path_static);
# BEGIN {
#         my $this = dirname( File::Spec->rel2abs( __FILE__ ) );
#         ($this) = $this =~ /(.+)/msx; # Make it non-tainted
#         chdir $this;
#     ($path_first, $path_second, $path_third) = (
#         File::Spec->catdir($this, '.env-first'),
#         File::Spec->catdir($this, '.env-second'),
#         File::Spec->catdir($this, '.env-third'),
#         );
#     ($path_interpolation, $path_static) = (
#         File::Spec->catdir($this, '.env-interpolation'),
#         File::Spec->catdir($this, '.env-static'),
#         );
# }

# subtest 'Three dotenv files: natural order' => sub {
#     # Do not use __FILE__ because its value is not absolute and not updated
#     # when chdir is done.
#     my $this = getcwd;
#     ($this) = $this =~ /(.+)/msx; # Make it non-tainted
#     my %new_env = (
#         'ENVDOT_FILEPATHS' => "$path_first:$path_second:$path_third",
#     );
#
#     # We need to replace the current %ENV, not change individual values.
#     ## no critic [Variables::RequireLocalizedPunctuationVars]
#     %ENV = %new_env;
#
#     my $r = eval <<"END_OF_TEXT"; ## no critic [BuiltinFunctions::ProhibitStringyEval]
# use Env::Dot;
# END_OF_TEXT
#
#     is( $ENV{'FOURTH'}, 'FOURTH: first file', 'Interface works' );
#     is( $ENV{'THIRD'}, 'THIRD: first file', 'Interface works' );
#     is( $ENV{'SECOND'}, 'SECOND: first file', 'Interface works' );
#     is( $ENV{'FIRST'}, 'FIRST: first file', 'Interface works' );
#     is( $ENV{'FROM_FIRST'}, 'FIRST: from first', 'Interface works' );
#     is( $ENV{'FROM_SECOND'}, 'SECOND: from second', 'Interface works' );
#     is( $ENV{'FROM_THIRD'}, 'THIRD: from third', 'Interface works' );
#
#     done_testing;
# };
#
# subtest 'Three dotenv files: reversed order' => sub {
#     # Do not use __FILE__ because its value is not absolute and not updated
#     # when chdir is done.
#     my $this = getcwd;
#     ($this) = $this =~ /(.+)/msx; # Make it non-tainted
#     my %new_env = (
#         'ENVDOT_FILEPATHS' => "$path_third:$path_second:$path_first",
#     );
#
#     # We need to replace the current %ENV, not change individual values.
#     ## no critic [Variables::RequireLocalizedPunctuationVars]
#     %ENV = %new_env;
#
#     my $r = eval <<"END_OF_TEXT"; ## no critic [BuiltinFunctions::ProhibitStringyEval]
# use Env::Dot;
# END_OF_TEXT
#
#     is( $ENV{'FOURTH'}, 'FOURTH: third file', 'Interface works' );
#     is( $ENV{'THIRD'}, 'THIRD: third file', 'Interface works' );
#     is( $ENV{'SECOND'}, 'SECOND: third file', 'Interface works' );
#     is( $ENV{'FIRST'}, 'FIRST: third file', 'Interface works' );
#     is( $ENV{'FROM_FIRST'}, 'FIRST: from first', 'Interface works' );
#     is( $ENV{'FROM_SECOND'}, 'SECOND: from second', 'Interface works' );
#     is( $ENV{'FROM_THIRD'}, 'THIRD: from third', 'Interface works' );
#
#     done_testing;
# };
#
# subtest 'Three dotenv files: mixed order' => sub {
#     # Do not use __FILE__ because its value is not absolute and not updated
#     # when chdir is done.
#     my $this = getcwd;
#     ($this) = $this =~ /(.+)/msx; # Make it non-tainted
#     my %new_env = (
#         'ENVDOT_FILEPATHS' => "$path_second:$path_third:$path_first",
#     );
#
#     # We need to replace the current %ENV, not change individual values.
#     ## no critic [Variables::RequireLocalizedPunctuationVars]
#     %ENV = %new_env;
#
#     my $r = eval <<"END_OF_TEXT"; ## no critic [BuiltinFunctions::ProhibitStringyEval]
# use Env::Dot;
# END_OF_TEXT
#
#     is( $ENV{'FOURTH'}, 'FOURTH: second file', 'Interface works' );
#     is( $ENV{'THIRD'}, 'THIRD: second file', 'Interface works' );
#     is( $ENV{'SECOND'}, 'SECOND: second file', 'Interface works' );
#     is( $ENV{'FIRST'}, 'FIRST: second file', 'Interface works' );
#     is( $ENV{'FROM_FIRST'}, 'FIRST: from first', 'Interface works' );
#     is( $ENV{'FROM_SECOND'}, 'SECOND: from second', 'Interface works' );
#     is( $ENV{'FROM_THIRD'}, 'THIRD: from third', 'Interface works' );
#
#     done_testing;
# };

done_testing;
