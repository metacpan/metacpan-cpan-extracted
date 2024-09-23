#!perl
## no critic (Subroutines::ProtectPrivateSubs)
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strict;
use warnings;
use Test2::V0;

use Carp;
use FileHandle ();
use File::Path qw( make_path );
use File::Spec;
use File::Temp ();
use Cwd        qw( getcwd abs_path );

use Env::Dot::Functions ();

# $File::Temp::KEEP_ALL = 1;
# $File::Temp::DEBUG = 1;
sub create_case_one {
    my ( $root_env, $dir_env, $subdir_env ) = @_;
    my $dir = File::Temp->newdir(
        TEMPLATE => 'temp-envdot-test-XXXXX',
        CLEANUP  => 1,
        DIR      => File::Spec->tmpdir,
    );
    my $dir_path = abs_path( $dir->{'DIRNAME'} );
    diag "Created temp dir: $dir_path";
    make_path( File::Spec->catdir( $dir_path, 'root', 'dir', 'subdir' ) );

    my $fh_root_env = FileHandle->new( File::Spec->catfile( $dir_path, 'root', '.env' ), 'w' );
    print {$fh_root_env} $root_env || croak;
    $fh_root_env->close;

    my $fh_dir_env = FileHandle->new( File::Spec->catfile( $dir_path, 'root', 'dir', '.env' ), 'w' );
    print {$fh_dir_env} $dir_env || croak;
    $fh_dir_env->close;

    my $fh_subdir_env = FileHandle->new( File::Spec->catfile( $dir_path, 'root', 'dir', 'subdir', '.env' ), 'w' );
    print {$fh_subdir_env} $subdir_env || croak;
    $fh_subdir_env->close;

    return $dir, $dir_path;
}

my $CASE_ONE_ROOT_ENV = <<"END_OF_FILE";
ROOT_VAR="root"
COMMON_VAR="root"
DIR_COMMON_VAR="root"
END_OF_FILE

my $CASE_ONE_DIR_ENV = <<"END_OF_FILE";
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

my $CASE_TWO_DIR_ENV = <<"END_OF_FILE";
DIR_VAR="dir"
COMMON_VAR="dir"
DIR_COMMON_VAR="dir"
# envdot (broken:option)
SUBDIR_COMMON_VAR="dir"
END_OF_FILE

subtest 'Private Subroutine _interpret_opts()' => sub {

    {
        my $opts_str = 'exact=1';
        my $opts     = Env::Dot::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 1, );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=0';
        my $opts     = Env::Dot::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 0, );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=123';
        my $opts     = Env::Dot::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 123, );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=1.234';
        my $opts     = Env::Dot::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 1.234, );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=1,234';
        my $opts     = Env::Dot::Functions::_interpret_opts($opts_str);
        my %expected = (
            exact => 1,
            234   => 1,    # Option without a value is interpreted as boolean with true value.
        );
        is( $opts, \%expected, 'Read options successfully, but options not valid' );
    }

    {
        my $opts_str = 'key_1=1,key_2=234, key_3=text , key_4=more text, key_5=';
        my $opts     = Env::Dot::Functions::_interpret_opts($opts_str);
        my %expected = (
            key_1 => 1,
            key_2 => 234,
            key_3 => 'text',
            key_4 => 'more text',
            key_5 => q{},
        );
        is( $opts, \%expected, 'Read options successfully' );
    }

    done_testing;
};

subtest 'Private Subroutine _interpret_dotenv()' => sub {

    my $dummy_fp = '/dummy/path/to/.env';

    # ###############################################################
    {
        my $dotenv = <<'END_OF_TEXT';
# envdot (unknown:option)
FIRST_VAR='My first var'
END_OF_TEXT

        like(
            dies { Env::Dot::Functions::_interpret_dotenv( $dummy_fp, split qr{\n}msx, $dotenv ) },
            qr{^ Unknown \s envdot \s option: \s 'unknown:option'! \s line \s 1 \s file \s '$dummy_fp' .* $}msx,
            'Died because of unknown option error',
        );
    }

    # ###############################################################
    {
        my $dotenv = <<'END_OF_TEXT';
FIRST_VAR='My first var'
# envdot (bad:option)
END_OF_TEXT

        like(
            dies { Env::Dot::Functions::_interpret_dotenv( $dummy_fp, split qr{\n}msx, $dotenv ) },
            qr{^ Unknown \s envdot \s option: \s 'bad:option'! \s line \s 2 \s file \s '$dummy_fp' .* $}msx,
            'Died because of bad option error',
        );
    }

    # ###############################################################
    {
        my $dotenv = <<'END_OF_TEXT';
FIFTH_VAR=123
SIXTH_VAR = !"#¤&%123.456
# Faulty row next
# envdot (:r)
END_OF_TEXT

        like(
            dies { Env::Dot::Functions::_interpret_dotenv( $dummy_fp, split qr{\n}msx, $dotenv ) },
            qr{^ Unknown \s envdot \s option: \s ':r'! \s line \s 4 \s file \s '$dummy_fp' .* $}msx,
            'Died because of invalid line error',
        );
    }

    # ###############################################################
    {
        my $dotenv = <<'END_OF_TEXT';
FIFTH_VAR=123
SIXTH_VAR = !"#¤&%123.456
# Faulty row next
qwerty
END_OF_TEXT

        like(
            dies { Env::Dot::Functions::_interpret_dotenv( $dummy_fp, split qr{\n}msx, $dotenv ) },
            qr{^ Invalid \s line: \s 'qwerty'! \s line \s 4 \s file \s '$dummy_fp' .* $}msx,
            'Died because of invalid line error',
        );
    }

    # ###############################################################
    {
        my $dotenv = <<'END_OF_TEXT';
# Here's some envs
# envdot (file:type=shell,read:from_parent)

FIRST_VAR='My first var'
THIRD_VAR="My third var"
# envdot (file:type=plain)
# The quotation marks become part of the variable value.
SECOND_VAR='My second var'
FIFTH_VAR=123
SIXTH_VAR=123.456
END_OF_TEXT

        my %r        = Env::Dot::Functions::_interpret_dotenv( $dummy_fp, split qr{\n}msx, $dotenv );
        my @vars     = @{ $r{'vars'} };
        my %opts     = %{ $r{'opts'} };
        my %def_opts = ( allow_interpolate => 0, );
        is(
            \@vars,
            [
                { name => q{FIRST_VAR},  value => q{My first var},    opts => \%def_opts, },
                { name => q{THIRD_VAR},  value => q{My third var},    opts => \%def_opts, },
                { name => q{SECOND_VAR}, value => q{'My second var'}, opts => \%def_opts, },
                { name => q{FIFTH_VAR},  value => q{123},             opts => \%def_opts, },
                { name => q{SIXTH_VAR},  value => q{123.456},         opts => \%def_opts, },
            ],
            'dotenv file correctly interpreted'
        );
        is(
            \%opts,
            {
                'read:from_parent'          => 1,
                'read:allow_missing_parent' => 0,
                'file:type'                 => 'plain',
                'var:allow_interpolate'     => 0,
            },
            'dotenv file correctly interpreted: opts'
        );
    }

    # ###############################################################
    {
        my $dotenv = <<'END_OF_TEXT';
# envdot (read:from_parent)
# Here's some envs
# envdot (file:type=plain)
THIRD_VAR=My third var
SECOND_VAR=My second var!@#$ %  # no comment allowed here

# envdot (file:type=shell)
FIRST_VAR='My first var'; export FIRST_VAR
FOURTH_VAR='My fourth var'
FIFTH_VAR=123
SIXTH_VAR=123.456
export SEVENTH_VAR=7654321

END_OF_TEXT

        my %r        = Env::Dot::Functions::_interpret_dotenv( $dummy_fp, split qr{\n}msx, $dotenv );
        my @vars     = @{ $r{'vars'} };
        my %opts     = %{ $r{'opts'} };
        my %def_opts = ( allow_interpolate => 0, );
        ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
        is(
            \@vars,
            [
                { name => q{THIRD_VAR},   value => q{My third var},                                   opts => \%def_opts, },
                { name => q{SECOND_VAR},  value => q{My second var!@#$ %  # no comment allowed here}, opts => \%def_opts, },
                { name => q{FIRST_VAR},   value => q{My first var},                                   opts => \%def_opts, },
                { name => q{FOURTH_VAR},  value => q{My fourth var},                                  opts => \%def_opts, },
                { name => q{FIFTH_VAR},   value => q{123},                                            opts => \%def_opts, },
                { name => q{SIXTH_VAR},   value => q{123.456},                                        opts => \%def_opts, },
                { name => q{SEVENTH_VAR}, value => q{7654321},                                        opts => \%def_opts, },
            ],
            'dotenv file correctly interpreted'
        );
        is(
            \%opts,
            {
                'read:from_parent'          => 1,
                'read:allow_missing_parent' => 0,
                'file:type'                 => 'shell',
                'var:allow_interpolate'     => 0,
            },
            'dotenv file correctly interpreted: opts'
        );
    }

    # ###############################################################
    {
        my $dotenv = <<'END_OF_TEXT';
FIFTH_VAR=123
SIXTH_VAR=123.456
END_OF_TEXT

        my %r        = Env::Dot::Functions::_interpret_dotenv( $dummy_fp, split qr{\n}msx, $dotenv );
        my @vars     = @{ $r{'vars'} };
        my %opts     = %{ $r{'opts'} };
        my %def_opts = ( allow_interpolate => 0, );
        is(
            \@vars,
            [
                { name => q{FIFTH_VAR}, value => q{123},     opts => \%def_opts, },
                { name => q{SIXTH_VAR}, value => q{123.456}, opts => \%def_opts, },
            ],
            'dotenv file correctly interpreted'
        );
        is(
            \%opts,
            {
                'read:from_parent'          => 0,
                'read:allow_missing_parent' => 0,
                'file:type'                 => 'shell',
                'var:allow_interpolate'     => 0,
            },
            'dotenv file correctly interpreted: opts'
        );
    }

    done_testing;
};

subtest 'Private subroutine _read_dotenv_file_recursively()' => sub {
    my ( $temp_dir, $temp_dir_path ) = create_case_one( $CASE_ONE_ROOT_ENV, $CASE_TWO_DIR_ENV, $CASE_ONE_SUBDIR_ENV, );

    # my $dir_path = File::Spec->catdir( $temp_dir_path, 'root', 'dir' );
    my $dir_filepath    = File::Spec->catdir( $temp_dir_path, 'root', 'dir', '.env' );
    my $subdir_path     = File::Spec->catdir( $temp_dir_path, 'root', 'dir', 'subdir' );
    my $subdir_filepath = File::Spec->catdir( $temp_dir_path, 'root', 'dir', 'subdir', '.env' );

    # Save cwd, cd to subdir, the bottom in the hierarcy.
    my $org_dir = getcwd;
    chdir $subdir_path || croak;

    like(
        ## no critic (RegularExpressions::ProhibitComplexRegexes)
        dies { Env::Dot::Functions::_read_dotenv_file_recursively($subdir_filepath) },

        # qr/Unknown \s envdot \s option: \s 'broken:option' \s row \s 4 \s file \s $dir_filepath .*$/msx,
        qr{^ Unknown \s envdot \s option: \s 'broken:option'! \s line \s 4 \s file \s '$dir_filepath' .* $}msx,
        'Died because of unknown option error',
    );

    chdir $org_dir || croak;

    done_testing;
};

subtest 'Private subroutine _get_parent_dotenv_filepath()' => sub {
    my ( $temp_dir, $temp_dir_path ) = create_case_one( $CASE_ONE_ROOT_ENV, $CASE_ONE_DIR_ENV, $CASE_ONE_SUBDIR_ENV, );

    my $root_path       = File::Spec->catdir( $temp_dir_path, 'root' );
    my $root_filepath   = File::Spec->catfile( $temp_dir_path, 'root', '.env' );
    my $dir_path        = File::Spec->catdir( $temp_dir_path, 'root', 'dir' );
    my $dir_filepath    = File::Spec->catdir( $temp_dir_path, 'root', 'dir', '.env' );
    my $subdir_path     = File::Spec->catdir( $temp_dir_path, 'root', 'dir', 'subdir' );
    my $subdir_filepath = File::Spec->catdir( $temp_dir_path, 'root', 'dir', 'subdir', '.env' );

    # Save cwd, cd to subdir, the bottom in the hierarcy.
    my $org_dir = getcwd;
    chdir $subdir_path || croak;

    my $parent_filepath = Env::Dot::Functions::_get_parent_dotenv_filepath($subdir_filepath);
    is( $parent_filepath, $dir_filepath, 'correct parent dir and .env file' );

    $parent_filepath = Env::Dot::Functions::_get_parent_dotenv_filepath($parent_filepath);
    is( $parent_filepath, $root_filepath, 'correct parent dir and .env file' );

    # # This is bit dangerous because the user could have .env file
    # # in root or in /tmp.
    # # Fix this.
    # $parent_filepath = Env::Dot::Functions::_get_parent_dotenv_filepath($parent_filepath);
    # is( $parent_filepath, undef, 'correct parent dir and .env file' );

    # Jump over middle directory.
    unlink $dir_filepath;

    # diag "Env::Dot::Functions::_get_parent_dotenv_filepath($subdir_filepath)";
    $parent_filepath = Env::Dot::Functions::_get_parent_dotenv_filepath($subdir_filepath);
    is( $parent_filepath, $root_filepath, 'correct parent dir and .env file' );

    chdir $org_dir || croak;

    done_testing;
};

done_testing;
