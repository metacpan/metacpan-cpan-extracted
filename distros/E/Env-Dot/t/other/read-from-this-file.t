#!perl
use strict;
use warnings;
use 5.010;
use Test2::V0;

use FindBin 1.51 qw( $RealBin );
use File::Spec   ();
use Carp;
use Cwd qw( getcwd );

my $lib_path;

BEGIN {
    $lib_path = File::Spec->catdir( ( $RealBin =~ /(.+)/msx )[0], q{..}, q{lib} );
}
use lib $lib_path;

my $deeper_path;
my ( $dir, $dir_path );    # $dir (the temp dir) must be in scope till program end

BEGIN {
    use Env::Dot::Test::Utils qw( create_test_file );
    ( $dir, $dir_path ) = create_test_file( [qw( deeper )], '.env',
        qq{# shellcheck disable=SC2034\n} . qq{OTHER_DEEPER_READ_FROM_THIS_FILE=OtherDeeperEnv\n} );
    $deeper_path = File::Spec->catdir( $dir_path, qw( deeper ) );
    diag "dir_path: $deeper_path";
    my $cwd = getcwd();
    chdir $deeper_path;
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    eval 'use Env::Dot "read"; 1;' || croak 'Not able to execute eval';
    chdir $cwd;
    is( $ENV{OTHER_DEEPER_READ_FROM_THIS_FILE}, 'OtherDeeperEnv', 'Read from correct .env file' );
}

done_testing;
