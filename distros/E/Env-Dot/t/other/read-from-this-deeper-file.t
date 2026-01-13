#!perl
use strict;
use warnings;
use 5.010;

use Test2::V0;

use File::Spec   ();
use FindBin 1.51 qw( $RealBin );

my $lib_path;

BEGIN {
    $lib_path = File::Spec->catdir( ( $RealBin =~ /(.+)/msx )[0], q{..}, q{lib} );
}
use lib $lib_path;

my $other_path;
my ( $dir, $dir_path );    # $dir (the temp dir) must be in scope till program end

BEGIN {
    use Env::Dot::Test::Utils qw( create_test_file );
    ( $dir, $dir_path ) = create_test_file( [qw( deeper )], '.env',
        qq{# shellcheck disable=SC2034\n} . qq{OTHER_DEEPER_READ_FROM_THIS_FILE=OtherDeeperEnv\n} );
    $other_path = File::Spec->catfile( $dir_path, qw( deeper .env ) );
    diag "Other path: $other_path";
}

use Env::Dot read => { dotenv_file => $other_path, };

is( $ENV{OTHER_DEEPER_READ_FROM_THIS_FILE}, 'OtherDeeperEnv', 'Read from correct .env file' );

done_testing;
