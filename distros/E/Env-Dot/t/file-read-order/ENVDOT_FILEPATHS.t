#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;

use Cwd qw( getcwd );
use English qw( -no_match_vars );
use File::Spec ();
use File::Basename qw( dirname );
use FindBin qw( $RealBin );

use Test2::V1 qw( -utf8 );
use Test2::Tools::Subtest qw( subtest_streamed );

my $lib_path;
BEGIN {
    $lib_path = File::Spec->catdir(($RealBin =~ /(.+)/msx)[0], q{.}, 'lib');
}
use lib "$lib_path";

# First thing change dir!
my ($path_first, $path_second, $path_third);
my ($path_interpolation, $path_static);
BEGIN {
    my $this = dirname( File::Spec->rel2abs( __FILE__ ) );
    ($this) = $this =~ /(.+)/msx; # Make it non-tainted
    chdir $this;
    ($path_first, $path_second, $path_third) = (
        File::Spec->catdir($this, 'dummy.env-first'),
        File::Spec->catdir($this, 'dummy.env-second'),
        File::Spec->catdir($this, 'dummy.env-third'),
        );
    ($path_interpolation, $path_static) = (
        File::Spec->catdir($this, 'dummy.env-interpolation'),
        File::Spec->catdir($this, 'dummy.env-static'),
        );
}

my %DOS_PLATFORMS = (
        'dos'     => 'MS-DOS/PC-DOS',
        'os2'     => 'OS/2',
        'MSWin32' => 'Windows',
        'cygwin'  => 'Cygwin',
    );

sub concat_filepaths {
    my @paths = @_;
    if( exists $DOS_PLATFORMS{ $OSNAME } ) {
        return join q{;}, @paths;
    } else {
        return join q{:}, @paths;
    }
}

subtest_streamed 'Three dotenv files: natural order' => sub {
    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx; # Make it non-tainted
    my %new_env = (
        'ENVDOT_FILEPATHS' => concat_filepaths($path_first, $path_second, $path_third),
    );
    T2->note("'ENVDOT_FILEPATHS' => $new_env{ENVDOT_FILEPATHS}");

    # We need to replace the current %ENV, not change individual values.
    ## no critic [Variables::RequireLocalizedPunctuationVars]
    %ENV = %new_env;

    my $r = eval <<"END_OF_TEXT"; ## no critic [BuiltinFunctions::ProhibitStringyEval]
use Env::Dot;
END_OF_TEXT

    T2->is( $ENV{'FOURTH'}, 'FOURTH: first file', 'Interface works' );
    T2->is( $ENV{'THIRD'}, 'THIRD: first file', 'Interface works' );
    T2->is( $ENV{'SECOND'}, 'SECOND: first file', 'Interface works' );
    T2->is( $ENV{'FIRST'}, 'FIRST: first file', 'Interface works' );
    T2->is( $ENV{'FROM_FIRST'}, 'FIRST: from first', 'Interface works' );
    T2->is( $ENV{'FROM_SECOND'}, 'SECOND: from second', 'Interface works' );
    T2->is( $ENV{'FROM_THIRD'}, 'THIRD: from third', 'Interface works' );

    T2->done_testing;
};

subtest_streamed 'Three dotenv files: reversed order' => sub {
    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx; # Make it non-tainted
    my %new_env = (
        'ENVDOT_FILEPATHS' => concat_filepaths($path_third, $path_second, $path_first),
    );
    T2->note("'ENVDOT_FILEPATHS' => $new_env{ENVDOT_FILEPATHS}");

    # We need to replace the current %ENV, not change individual values.
    ## no critic [Variables::RequireLocalizedPunctuationVars]
    %ENV = %new_env;

    my $r = eval <<"END_OF_TEXT"; ## no critic [BuiltinFunctions::ProhibitStringyEval]
use Env::Dot;
END_OF_TEXT

    T2->is( $ENV{'FOURTH'}, 'FOURTH: third file', 'Interface works' );
    T2->is( $ENV{'THIRD'}, 'THIRD: third file', 'Interface works' );
    T2->is( $ENV{'SECOND'}, 'SECOND: third file', 'Interface works' );
    T2->is( $ENV{'FIRST'}, 'FIRST: third file', 'Interface works' );
    T2->is( $ENV{'FROM_FIRST'}, 'FIRST: from first', 'Interface works' );
    T2->is( $ENV{'FROM_SECOND'}, 'SECOND: from second', 'Interface works' );
    T2->is( $ENV{'FROM_THIRD'}, 'THIRD: from third', 'Interface works' );

    T2->done_testing;
};

subtest_streamed 'Three dotenv files: mixed order' => sub {
    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx; # Make it non-tainted
    my %new_env = (
        'ENVDOT_FILEPATHS' => concat_filepaths($path_second, $path_third, $path_first),
    );
    T2->note("'ENVDOT_FILEPATHS' => $new_env{ENVDOT_FILEPATHS}");

    # We need to replace the current %ENV, not change individual values.
    ## no critic [Variables::RequireLocalizedPunctuationVars]
    %ENV = %new_env;

    my $r = eval <<"END_OF_TEXT"; ## no critic [BuiltinFunctions::ProhibitStringyEval]
use Env::Dot;
END_OF_TEXT

    T2->is( $ENV{'FOURTH'}, 'FOURTH: second file', 'Interface works' );
    T2->is( $ENV{'THIRD'}, 'THIRD: second file', 'Interface works' );
    T2->is( $ENV{'SECOND'}, 'SECOND: second file', 'Interface works' );
    T2->is( $ENV{'FIRST'}, 'FIRST: second file', 'Interface works' );
    T2->is( $ENV{'FROM_FIRST'}, 'FIRST: from first', 'Interface works' );
    T2->is( $ENV{'FROM_SECOND'}, 'SECOND: from second', 'Interface works' );
    T2->is( $ENV{'FROM_THIRD'}, 'THIRD: from third', 'Interface works' );

    T2->done_testing;
};

subtest_streamed 'Two dotenv files: natural order, and from env' => sub {
    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx; # Make it non-tainted
    my %new_env = (
        'ENVDOT_FILEPATHS' => concat_filepaths($path_first, $path_second),
        'FROM_ENV' => 'ENV: from env',
    );
    T2->note("'ENVDOT_FILEPATHS' => $new_env{ENVDOT_FILEPATHS}");

    # We need to replace the current %ENV, not change individual values.
    ## no critic [Variables::RequireLocalizedPunctuationVars]
    %ENV = %new_env;

    my $r = eval <<"END_OF_TEXT"; ## no critic [BuiltinFunctions::ProhibitStringyEval]
use Env::Dot;
END_OF_TEXT

    T2->is( $ENV{'FOURTH'}, 'FOURTH: first file', 'Interface works' );
    T2->is( $ENV{'THIRD'}, 'THIRD: first file', 'Interface works' );
    T2->is( $ENV{'SECOND'}, 'SECOND: first file', 'Interface works' );
    T2->is( $ENV{'FIRST'}, 'FIRST: first file', 'Interface works' );
    T2->is( $ENV{'FROM_FIRST'}, 'FIRST: from first', 'Interface works' );
    T2->is( $ENV{'FROM_SECOND'}, 'SECOND: from second', 'Interface works' );
    T2->is( $ENV{'FROM_ENV'}, 'ENV: from env', 'Interface works' );

    T2->done_testing;
};

subtest_streamed 'Two dotenv files requiring interpolating (not done): reversed order, and from env' => sub {
    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx; # Make it non-tainted
    my %new_env = (
        'ENVDOT_FILEPATHS' => concat_filepaths($path_interpolation, $path_static),
        'COMMON_VAR' => 'COMMON: from env',
    );
    T2->note("'ENVDOT_FILEPATHS' => $new_env{ENVDOT_FILEPATHS}");

    # We need to replace the current %ENV, not change individual values.
    ## no critic [Variables::RequireLocalizedPunctuationVars]
    %ENV = %new_env;

    my $r = eval <<"END_OF_TEXT"; ## no critic [BuiltinFunctions::ProhibitStringyEval]
use Env::Dot;
END_OF_TEXT

    T2->is( $ENV{'DYNAMIC_VAR'}, '$(pwd)/${ANOTHER_VAR}', 'Interface works' ); ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    T2->is( $ENV{'DYNAMIC_DIR'}, '`pwd`', 'Interface works' );
    T2->is( $ENV{'STATIC_VAR'}, 'STATIC: static file', 'Interface works' );
    T2->is( $ENV{'FROM_INTERPOLATION'}, 'INTERPOLATION: from interpolation', 'Interface works' );
    T2->is( $ENV{'FROM_STATIC'}, 'STATIC: from static', 'Interface works' );
    T2->is( $ENV{'COMMON_VAR'}, 'COMMON: from env', 'Interface works' );

    T2->done_testing;
};

T2->done_testing;
