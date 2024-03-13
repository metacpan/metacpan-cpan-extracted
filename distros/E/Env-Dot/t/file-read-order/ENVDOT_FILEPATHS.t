#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;
use Test2::V0;

use File::Spec     ();
use File::Basename qw( dirname );
use Cwd;

# First thing change dir!
my ( $path_first, $path_second, $path_third );
my ( $path_interpolation, $path_static );

BEGIN {
    my $this = dirname( File::Spec->rel2abs(__FILE__) );
    ($this) = $this =~ /(.+)/msx;    # Make it non-tainted
    chdir $this;
    ( $path_first, $path_second, $path_third ) = (
        File::Spec->catdir( $this, 'dummy.env-first' ),
        File::Spec->catdir( $this, 'dummy.env-second' ),
        File::Spec->catdir( $this, 'dummy.env-third' ),
    );
    ( $path_interpolation, $path_static ) =
      ( File::Spec->catdir( $this, 'dummy.env-interpolation' ), File::Spec->catdir( $this, 'dummy.env-static' ), );
}

subtest 'Three dotenv files: natural order' => sub {

    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx;    # Make it non-tainted
    my %new_env = ( 'ENVDOT_FILEPATHS' => "$path_first:$path_second:$path_third", );

    # We need to replace the current %ENV, not change individual values.
    ## no critic [Variables::RequireLocalizedPunctuationVars]
    %ENV = %new_env;

    my $r = eval <<"END_OF_TEXT";    ## no critic [BuiltinFunctions::ProhibitStringyEval]
use Env::Dot;
END_OF_TEXT

    is( $ENV{'FOURTH'},      'FOURTH: first file',  'Interface works' );
    is( $ENV{'THIRD'},       'THIRD: first file',   'Interface works' );
    is( $ENV{'SECOND'},      'SECOND: first file',  'Interface works' );
    is( $ENV{'FIRST'},       'FIRST: first file',   'Interface works' );
    is( $ENV{'FROM_FIRST'},  'FIRST: from first',   'Interface works' );
    is( $ENV{'FROM_SECOND'}, 'SECOND: from second', 'Interface works' );
    is( $ENV{'FROM_THIRD'},  'THIRD: from third',   'Interface works' );

    done_testing;
};

subtest 'Three dotenv files: reversed order' => sub {

    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx;    # Make it non-tainted
    my %new_env = ( 'ENVDOT_FILEPATHS' => "$path_third:$path_second:$path_first", );

    # We need to replace the current %ENV, not change individual values.
    ## no critic [Variables::RequireLocalizedPunctuationVars]
    %ENV = %new_env;

    my $r = eval <<"END_OF_TEXT";    ## no critic [BuiltinFunctions::ProhibitStringyEval]
use Env::Dot;
END_OF_TEXT

    is( $ENV{'FOURTH'},      'FOURTH: third file',  'Interface works' );
    is( $ENV{'THIRD'},       'THIRD: third file',   'Interface works' );
    is( $ENV{'SECOND'},      'SECOND: third file',  'Interface works' );
    is( $ENV{'FIRST'},       'FIRST: third file',   'Interface works' );
    is( $ENV{'FROM_FIRST'},  'FIRST: from first',   'Interface works' );
    is( $ENV{'FROM_SECOND'}, 'SECOND: from second', 'Interface works' );
    is( $ENV{'FROM_THIRD'},  'THIRD: from third',   'Interface works' );

    done_testing;
};

subtest 'Three dotenv files: mixed order' => sub {

    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx;    # Make it non-tainted
    my %new_env = ( 'ENVDOT_FILEPATHS' => "$path_second:$path_third:$path_first", );

    # We need to replace the current %ENV, not change individual values.
    ## no critic [Variables::RequireLocalizedPunctuationVars]
    %ENV = %new_env;

    my $r = eval <<"END_OF_TEXT";    ## no critic [BuiltinFunctions::ProhibitStringyEval]
use Env::Dot;
END_OF_TEXT

    is( $ENV{'FOURTH'},      'FOURTH: second file', 'Interface works' );
    is( $ENV{'THIRD'},       'THIRD: second file',  'Interface works' );
    is( $ENV{'SECOND'},      'SECOND: second file', 'Interface works' );
    is( $ENV{'FIRST'},       'FIRST: second file',  'Interface works' );
    is( $ENV{'FROM_FIRST'},  'FIRST: from first',   'Interface works' );
    is( $ENV{'FROM_SECOND'}, 'SECOND: from second', 'Interface works' );
    is( $ENV{'FROM_THIRD'},  'THIRD: from third',   'Interface works' );

    done_testing;
};

subtest 'Two dotenv files: natural order, and from env' => sub {

    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx;    # Make it non-tainted
    my %new_env = (
        'ENVDOT_FILEPATHS' => "$path_first:$path_second",
        'FROM_ENV'         => 'ENV: from env',
    );

    # We need to replace the current %ENV, not change individual values.
    ## no critic [Variables::RequireLocalizedPunctuationVars]
    %ENV = %new_env;

    my $r = eval <<"END_OF_TEXT";    ## no critic [BuiltinFunctions::ProhibitStringyEval]
use Env::Dot;
END_OF_TEXT

    is( $ENV{'FOURTH'},      'FOURTH: first file',  'Interface works' );
    is( $ENV{'THIRD'},       'THIRD: first file',   'Interface works' );
    is( $ENV{'SECOND'},      'SECOND: first file',  'Interface works' );
    is( $ENV{'FIRST'},       'FIRST: first file',   'Interface works' );
    is( $ENV{'FROM_FIRST'},  'FIRST: from first',   'Interface works' );
    is( $ENV{'FROM_SECOND'}, 'SECOND: from second', 'Interface works' );
    is( $ENV{'FROM_ENV'},    'ENV: from env',       'Interface works' );

    done_testing;
};

subtest 'Two dotenv files requiring interpolating (not done): reversed order, and from env' => sub {

    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx;    # Make it non-tainted
    my %new_env = (
        'ENVDOT_FILEPATHS' => "$path_interpolation:$path_static",
        'COMMON_VAR'       => 'COMMON: from env',
    );

    # We need to replace the current %ENV, not change individual values.
    ## no critic [Variables::RequireLocalizedPunctuationVars]
    %ENV = %new_env;

    my $r = eval <<"END_OF_TEXT";    ## no critic [BuiltinFunctions::ProhibitStringyEval]
use Env::Dot;
END_OF_TEXT

    is( $ENV{'DYNAMIC_VAR'},        '$(pwd)/${ANOTHER_VAR}',             'Interface works' );
    is( $ENV{'DYNAMIC_DIR'},        '`pwd`',                             'Interface works' );
    is( $ENV{'STATIC_VAR'},         'STATIC: static file',               'Interface works' );
    is( $ENV{'FROM_INTERPOLATION'}, 'INTERPOLATION: from interpolation', 'Interface works' );
    is( $ENV{'FROM_STATIC'},        'STATIC: from static',               'Interface works' );
    is( $ENV{'COMMON_VAR'},         'COMMON: from env',                  'Interface works' );

    done_testing;
};

done_testing;
