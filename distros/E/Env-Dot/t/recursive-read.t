#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;
use Test2::V0;

use Carp       qw( croak );
use English    qw( -no_match_vars );    # Avoids regex performance
use FileHandle ();
use File::Path qw( make_path );
use File::Spec ();
use File::Temp ();
use Cwd        qw( getcwd );

use FindBin qw( $RealBin );
my $lib_path;

BEGIN {
    $lib_path = File::Spec->catdir( ( $RealBin =~ /(.+)/msx )[0], q{.}, 'lib' );
}
use lib "$lib_path";

use Test2::Require::Platform::Unix;

# $File::Temp::KEEP_ALL = 1;
# $File::Temp::DEBUG = 1;
sub create_subtest_files {
    my ( $root_env, $dir_env, $subdir_env ) = @_;
    my $dir = File::Temp->newdir(
        TEMPLATE => 'temp-envdot-test-XXXXX',
        CLEANUP  => 1,
        DIR      => File::Spec->tmpdir,
    );
    my $dir_path = $dir->{'DIRNAME'};
    make_path( File::Spec->catdir( $dir_path, 'root', 'dir', 'subdir' ) );

    if ($root_env) {
        my $fh_root_env = FileHandle->new( File::Spec->catfile( $dir_path, 'root', '.env' ), 'w' );
        print {$fh_root_env} $root_env || croak;
        $fh_root_env->close;
    }

    if ($dir_env) {
        my $fh_dir_env = FileHandle->new( File::Spec->catfile( $dir_path, 'root', 'dir', '.env' ), 'w' );
        print {$fh_dir_env} $dir_env || croak;
        $fh_dir_env->close;
    }

    if ($subdir_env) {
        my $fh_subdir_env = FileHandle->new( File::Spec->catfile( $dir_path, 'root', 'dir', 'subdir', '.env' ), 'w' );
        print {$fh_subdir_env} $subdir_env || croak;
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

subtest 'One dotenv, two parent files' => sub {
    my ( $dir, $dir_path ) = create_subtest_files( $CASE_ONE_ROOT_ENV, $CASE_ONE_DIR_ENV, $CASE_ONE_SUBDIR_ENV, );

    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx;    # Make it non-tainted

    my $subdir_path = File::Spec->catdir( $dir_path, 'root', 'dir', 'subdir' );

    # CD to subdir, the bottom in the hierarcy.
    chdir $subdir_path || croak;

    my %new_env;
    ## no critic (ControlStructures::ProhibitPostfixControls)
    $new_env{$_} = $ENV{$_} foreach ( keys %ENV );

    delete $new_env{'ENVDOT_FILEPATHS'} if exists $new_env{'ENVDOT_FILEPATHS'};

    # We need to replace the current %ENV, not change individual values.
    local %ENV = %new_env;

    local $EVAL_ERROR = undef;
    my $r = eval 'use Env::Dot; 1';    ## no critic [BuiltinFunctions::ProhibitStringyEval]
    is( $EVAL_ERROR, q{}, 'use Env::Dot failed' );
    is( $r,          1,   'evaled okay' );

    is( $ENV{'ROOT_VAR'},          'root',   'Interface works' );
    is( $ENV{'DIR_VAR'},           'dir',    'Interface works' );
    is( $ENV{'SUBDIR_VAR'},        'subdir', 'Interface works' );
    is( $ENV{'COMMON_VAR'},        'subdir', 'Interface works' );
    is( $ENV{'DIR_COMMON_VAR'},    'dir',    'Interface works' );
    is( $ENV{'SUBDIR_COMMON_VAR'}, 'subdir', 'Interface works' );

    chdir $this;
    done_testing;
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

subtest 'Missing parent file, not okay' => sub {

    # N.B. This test will fail if there is a .env file in a parent dir of the tempdir.
    my ( $dir, $dir_path ) = create_subtest_files( undef, undef, $CASE_TWO_SUBDIR_ENV, );

    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx;    # Make it non-tainted

    my $subdir_path = File::Spec->catdir( $dir_path, 'root', 'dir', 'subdir' );
    my $subdir_env  = File::Spec->catdir( $dir_path, 'root', 'dir', 'subdir', '.env' );

    # CD to subdir, the bottom in the hierarcy.
    chdir $subdir_path || croak;

    my %new_env;
    ## no critic (ControlStructures::ProhibitPostfixControls)
    $new_env{$_} = $ENV{$_} foreach ( keys %ENV );

    delete $new_env{'ENVDOT_FILEPATHS'} if exists $new_env{'ENVDOT_FILEPATHS'};

    # We need to replace the current %ENV, not change individual values.
    local %ENV = %new_env;

    local $EVAL_ERROR = undef;
    my $r = eval 'use Env::Dot; 1';    ## no critic [BuiltinFunctions::ProhibitStringyEval]
    ## no critic (RegularExpressions::ProhibitComplexRegexes)
    like(
        $EVAL_ERROR,
        qr/^Error: \s No \s parent \s [.]env \s file \s found \s for \s child \s file \s '$subdir_env' .* $/msx,
        'use Env::Dot failed'
    );
    is( $r, U(), 'eval failed' );

    chdir $this;
    done_testing;
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

subtest 'Missing parent file 2, not okay' => sub {

    # N.B. This test will fail if there is a .env file in a parent dir of the tempdir.
    my ( $tmp_dir, $tmp_dir_path ) = create_subtest_files( undef, $CASE_THREE_DIR_ENV, $CASE_TWO_SUBDIR_ENV, );

    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx;    # Make it non-tainted

    my $dir_path    = File::Spec->catdir( $tmp_dir_path, 'root', 'dir' );
    my $dir_env     = File::Spec->catdir( $tmp_dir_path, 'root', 'dir', '.env' );
    my $subdir_path = File::Spec->catdir( $tmp_dir_path, 'root', 'dir', 'subdir' );

    # CD to subdir, the bottom in the hierarcy.
    chdir $subdir_path || croak;

    my %new_env;
    ## no critic (ControlStructures::ProhibitPostfixControls)
    $new_env{$_} = $ENV{$_} foreach ( keys %ENV );

    delete $new_env{'ENVDOT_FILEPATHS'} if exists $new_env{'ENVDOT_FILEPATHS'};

    # We need to replace the current %ENV, not change individual values.
    local %ENV = %new_env;

    local $EVAL_ERROR = undef;
    my $r = eval 'use Env::Dot; 1';    ## no critic [BuiltinFunctions::ProhibitStringyEval]
    ## no critic (RegularExpressions::ProhibitComplexRegexes)
    like(
        $EVAL_ERROR,
        qr/^Error: \s No \s parent \s [.]env \s file \s found \s for \s child \s file \s '$dir_env' .* $/msx,
        'use Env::Dot failed'
    );
    is( $r, U(), 'eval failed' );

    chdir $this;
    done_testing;
};

my $CASE_FOUR_SUBDIR_ENV = <<"END_OF_FILE";
# envdot (file:type=shell,read:from_parent=true,read:allow_missing_parent=true)
SUBDIR_VAR="subdir"
COMMON_VAR="subdir"
SUBDIR_COMMON_VAR="subdir"
END_OF_FILE

subtest 'Missing parent file, okay' => sub {

    # N.B. This test will fail if there is a .env file in a parent dir of the tempdir.
    my ( $dir, $dir_path ) = create_subtest_files( undef, undef, $CASE_FOUR_SUBDIR_ENV, );

    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx;    # Make it non-tainted

    my $subdir_path = File::Spec->catdir( $dir_path, 'root', 'dir', 'subdir' );

    # CD to subdir, the bottom in the hierarcy.
    chdir $subdir_path || croak;

    my %new_env;
    ## no critic (ControlStructures::ProhibitPostfixControls)
    $new_env{$_} = $ENV{$_} foreach ( keys %ENV );

    delete $new_env{'ENVDOT_FILEPATHS'} if exists $new_env{'ENVDOT_FILEPATHS'};

    # We need to replace the current %ENV, not change individual values.
    local %ENV = %new_env;

    local $EVAL_ERROR = undef;
    my $r = eval 'use Env::Dot; 1';    ## no critic [BuiltinFunctions::ProhibitStringyEval]
    is( $r,          1,   'evaled okay' );
    is( $EVAL_ERROR, q{}, 'use Env::Dot successful' );

    is( $ENV{'ROOT_VAR'},          U(),      'Interface works' );
    is( $ENV{'DIR_VAR'},           U(),      'Interface works' );
    is( $ENV{'SUBDIR_VAR'},        'subdir', 'Interface works' );
    is( $ENV{'COMMON_VAR'},        'subdir', 'Interface works' );
    is( $ENV{'DIR_COMMON_VAR'},    U(),      'Interface works' );
    is( $ENV{'SUBDIR_COMMON_VAR'}, 'subdir', 'Interface works' );

    chdir $this;
    done_testing;
};

done_testing;
