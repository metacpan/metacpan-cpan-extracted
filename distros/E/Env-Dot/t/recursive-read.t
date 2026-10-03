#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;

use Carp qw( croak );
use Cwd qw( getcwd abs_path );
use English qw( -no_match_vars ) ;  # Avoids regex performance
use FileHandle ();
use File::Path qw( make_path );
use File::Spec ();
use File::Temp ();

use Test2::V1 qw( -utf8 );
use Test2::Tools::Subtest qw( subtest_streamed );

use FindBin qw( $RealBin );
my $lib_path;
BEGIN {
    $lib_path = File::Spec->catdir(($RealBin =~ /(.+)/msx)[0], q{.}, 'lib');
}
use lib "$lib_path";

use Test2::Require::Platform::Unix;
require Env::Dot::Test::ChdirGuard;

# $File::Temp::KEEP_ALL = 1;
# $File::Temp::DEBUG = 1;
sub create_subtest_files {
    my ($root_env, $dir_env, $subdir_env) = @_;
    my $dir = File::Temp->newdir(
        TEMPLATE => 'temp-envdot-test-XXXXX',
        CLEANUP => 1,
        DIR => File::Spec->tmpdir,
    );
    my $dir_path = abs_path( $dir->dirname );
    make_path( File::Spec->catdir( $dir_path, 'root', 'dir', 'subdir' ) );

    if( $root_env ) {
        my $fh_root_env = FileHandle->new( File::Spec->catfile( $dir_path,
            'root', '.env' ), 'w' );
        print { $fh_root_env } $root_env || croak;
        $fh_root_env->close;
    }

    if( $dir_env ) {
        my $fh_dir_env = FileHandle->new( File::Spec->catfile( $dir_path,
            'root', 'dir', '.env' ), 'w' );
        print { $fh_dir_env } $dir_env || croak;
        $fh_dir_env->close;
    }

    if( $subdir_env ) {
        my $fh_subdir_env = FileHandle->new( File::Spec->catfile( $dir_path,
            'root', 'dir', 'subdir', '.env' ), 'w' );
        print { $fh_subdir_env } $subdir_env || croak;
        $fh_subdir_env->close;
    }

    return $dir, $dir_path;
}

my $CASE_ONE_ROOT_ENV = <<"END_OF_FILE";
ROOT_VAR="root"
COMMON_VAR="root"
DIR_COMMON_VAR="root"
END_OF_FILE

my $CASE_ONE_DIR_ENV = <<"END_OF_FILE";
# envdot (read:from_parent)
DIR_VAR="dir"
COMMON_VAR="dir"
DIR_COMMON_VAR="dir"
SUBDIR_COMMON_VAR="dir"
END_OF_FILE

my $CASE_ONE_SUBDIR_ENV = <<"END_OF_FILE";
# envdot (file:type=shell,read:from_parent)
SUBDIR_VAR="subdir"
COMMON_VAR="subdir"
SUBDIR_COMMON_VAR="subdir"
END_OF_FILE

# enter_test_dir( $dir )
#
# Returns a ChdirGuard that MUST be
# kept in a lexical by the caller; when it goes out of scope the cwd is
# restored to what it was at the moment of this call.
sub enter_test_dir {
    my ($dir) = @_;
    # chmod 0755, File::Spec->catfile($dir, $PRG) or croak "Cannot chmod: $OS_ERROR";
    my $guard = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $dir or croak "Cannot chdir: $OS_ERROR";
    return $guard;
}


subtest_streamed 'One dotenv, two parent files' => sub {
    my ($dir, $dir_path) = create_subtest_files(
        $CASE_ONE_ROOT_ENV,
        $CASE_ONE_DIR_ENV,
        $CASE_ONE_SUBDIR_ENV,
        );

    my $subdir_path = File::Spec->catdir( $dir_path, 'root', 'dir', 'subdir' );

    # CD to subdir, the bottom in the hierarcy.
    my $guard = enter_test_dir($subdir_path);

    my %new_env;
    ## no critic (ControlStructures::ProhibitPostfixControls)
    $new_env{$_} = $ENV{$_} foreach (keys %ENV);

    delete $new_env{'ENVDOT_FILEPATHS'} if exists $new_env{'ENVDOT_FILEPATHS'};

    # We need to replace the current %ENV, not change individual values.
    local %ENV = %new_env;

    local $EVAL_ERROR = undef;
    my $r = eval 'use Env::Dot; 1'; ## no critic [BuiltinFunctions::ProhibitStringyEval]
    T2->is($EVAL_ERROR, q{}, 'use Env::Dot failed' );
    T2->is( $r, 1, 'evaled okay');

    T2->is( $ENV{'ROOT_VAR'}, 'root', 'Interface works' );
    T2->is( $ENV{'DIR_VAR'}, 'dir', 'Interface works' );
    T2->is( $ENV{'SUBDIR_VAR'}, 'subdir', 'Interface works' );
    T2->is( $ENV{'COMMON_VAR'}, 'subdir', 'Interface works' );
    T2->is( $ENV{'DIR_COMMON_VAR'}, 'dir', 'Interface works' );
    T2->is( $ENV{'SUBDIR_COMMON_VAR'}, 'subdir', 'Interface works' );

    T2->done_testing;
};

# my $CASE_TWO_ROOT_ENV = <<"END_OF_FILE";
# # envdot (read:from_parent)
# ROOT_VAR="root"
# COMMON_VAR="root"
# DIR_COMMON_VAR="root"
# END_OF_FILE
#
# my $CASE_TWO_DIR_ENV = <<"END_OF_FILE";
# # envdot (read:from_parent)
# DIR_VAR="dir"
# COMMON_VAR="dir"
# DIR_COMMON_VAR="dir"
# SUBDIR_COMMON_VAR="dir"
# END_OF_FILE
#
my $CASE_TWO_SUBDIR_ENV = <<"END_OF_FILE";
# envdot (file:type=shell,read:from_parent)
SUBDIR_VAR="subdir"
COMMON_VAR="subdir"
SUBDIR_COMMON_VAR="subdir"
END_OF_FILE

subtest_streamed 'Missing parent file, not okay' => sub {
    # N.B. This test will fail if there is a .env file in a parent dir of the tempdir.
    my ($dir, $dir_path) = create_subtest_files(
        undef, undef, $CASE_TWO_SUBDIR_ENV,
        );

    my $subdir_path = File::Spec->catdir( $dir_path, 'root', 'dir', 'subdir' );
    my $subdir_env = File::Spec->catdir( $dir_path, 'root', 'dir', 'subdir', '.env' );

    # CD to subdir, the bottom in the hierarcy.
    my $guard = enter_test_dir($subdir_path);

    my %new_env;
    ## no critic (ControlStructures::ProhibitPostfixControls)
    $new_env{$_} = $ENV{$_} foreach (keys %ENV);

    delete $new_env{'ENVDOT_FILEPATHS'} if exists $new_env{'ENVDOT_FILEPATHS'};

    # We need to replace the current %ENV, not change individual values.
    local %ENV = %new_env;

    local $EVAL_ERROR = undef;
    my $r = eval 'use Env::Dot; 1'; ## no critic [BuiltinFunctions::ProhibitStringyEval]
    ## no critic (RegularExpressions::ProhibitComplexRegexes)
    T2->like( $EVAL_ERROR, qr/^Error: \s No \s parent \s [.]env \s file \s found \s for \s child \s file \s '$subdir_env' .* $/msx,
        'use Env::Dot failed' );
    T2->is( $r, T2->U(), 'eval failed');

    T2->done_testing;
};

# my $CASE_TWO_ROOT_ENV = <<"END_OF_FILE";
# # envdot (read:from_parent)
# ROOT_VAR="root"
# COMMON_VAR="root"
# DIR_COMMON_VAR="root"
# END_OF_FILE
#
my $CASE_THREE_DIR_ENV = <<"END_OF_FILE";
# envdot (read:from_parent=true,read:allow_missing_parent=false)
DIR_VAR="dir"
COMMON_VAR="dir"
DIR_COMMON_VAR="dir"
SUBDIR_COMMON_VAR="dir"
END_OF_FILE

my $CASE_THREE_SUBDIR_ENV = <<"END_OF_FILE";
# envdot (file:type=shell,read:from_parent)
SUBDIR_VAR="subdir"
COMMON_VAR="subdir"
SUBDIR_COMMON_VAR="subdir"
END_OF_FILE

subtest_streamed 'Missing parent file 2, not okay' => sub {
    # N.B. This test will fail if there is a .env file in a parent dir of the tempdir.
    my ($tmp_dir, $tmp_dir_path) = create_subtest_files(
        undef, $CASE_THREE_DIR_ENV, $CASE_TWO_SUBDIR_ENV,
        );

    my $dir_env = File::Spec->catdir( $tmp_dir_path, 'root', 'dir', '.env' );
    my $subdir_path = File::Spec->catdir( $tmp_dir_path, 'root', 'dir', 'subdir' );

    # CD to subdir, the bottom in the hierarcy.
    my $guard = enter_test_dir($subdir_path);

    my %new_env;
    ## no critic (ControlStructures::ProhibitPostfixControls)
    $new_env{$_} = $ENV{$_} foreach (keys %ENV);

    delete $new_env{'ENVDOT_FILEPATHS'} if exists $new_env{'ENVDOT_FILEPATHS'};

    # We need to replace the current %ENV, not change individual values.
    local %ENV = %new_env;

    local $EVAL_ERROR = undef;
    my $r = eval 'use Env::Dot; 1'; ## no critic [BuiltinFunctions::ProhibitStringyEval]
    ## no critic (RegularExpressions::ProhibitComplexRegexes)
    T2->like( $EVAL_ERROR, qr/^Error: \s No \s parent \s [.]env \s file \s found \s for \s child \s file \s '$dir_env' .* $/msx,
        'use Env::Dot failed' );
    T2->is( $r, T2->U(), 'eval failed');

    T2->done_testing;
};

my $CASE_FOUR_SUBDIR_ENV = <<"END_OF_FILE";
# envdot (file:type=shell,read:from_parent=true,read:allow_missing_parent=true)
SUBDIR_VAR="subdir"
COMMON_VAR="subdir"
SUBDIR_COMMON_VAR="subdir"
END_OF_FILE

subtest_streamed 'Missing parent file, okay' => sub {
    # N.B. This test will fail if there is a .env file in a parent dir of the tempdir.
    my ($dir, $dir_path) = create_subtest_files(
        undef, undef, $CASE_FOUR_SUBDIR_ENV,
        );

    my $subdir_path = File::Spec->catdir( $dir_path, 'root', 'dir', 'subdir' );

    # CD to subdir, the bottom in the hierarcy.
    my $guard = enter_test_dir($subdir_path);

    my %new_env;
    ## no critic (ControlStructures::ProhibitPostfixControls)
    $new_env{$_} = $ENV{$_} foreach (keys %ENV);

    delete $new_env{'ENVDOT_FILEPATHS'} if exists $new_env{'ENVDOT_FILEPATHS'};

    # We need to replace the current %ENV, not change individual values.
    local %ENV = %new_env;

    local $EVAL_ERROR = undef;
    my $r = eval 'use Env::Dot; 1'; ## no critic [BuiltinFunctions::ProhibitStringyEval]
    T2->is( $r, 1, 'evaled okay');
    T2->is($EVAL_ERROR, q{}, 'use Env::Dot successful' );

    T2->is( $ENV{'ROOT_VAR'}, T2->U(), 'Interface works' );
    T2->is( $ENV{'DIR_VAR'}, T2->U(), 'Interface works' );
    T2->is( $ENV{'SUBDIR_VAR'}, 'subdir', 'Interface works' );
    T2->is( $ENV{'COMMON_VAR'}, 'subdir', 'Interface works' );
    T2->is( $ENV{'DIR_COMMON_VAR'}, T2->U(), 'Interface works' );
    T2->is( $ENV{'SUBDIR_COMMON_VAR'}, 'subdir', 'Interface works' );

    T2->done_testing;
};

T2->done_testing;
