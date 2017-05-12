use strict;
use warnings;

use Test::More;

# FILENAME: 01-apptest_unconfigured.t
# CREATED: 04/08/11 18:46:16 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test that dzil runs on an unconfigured dist

use FindBin;
use File::Spec::Functions qw( catdir rel2abs );
use File::Temp qw( tempdir );
use File::Copy::Recursive qw( dircopy );
use File::pushd qw( pushd );

{
    my $result = eval { system( 'dzil', '-v' ); };
    plan skip_all => "Skip when dzil is not call-able.\n" if $result eq '-1';
}

my $root = catdir( rel2abs($FindBin::Bin), 'apptest', '02_basic_config' );
my $tmpdir = tempdir( CLEANUP => 1 );
my $bdir = catdir( $tmpdir, '02_basic_config' );

note explain { root => $root, tmpdir => $tmpdir, bdir => $bdir };

ok( dircopy( $root, $bdir ), "Copied directory to tmpdir" )
    or diag explain {
    args  => [ $root, $bdir ],
    error => $!,
    };

{
    my $dir = pushd($bdir);
    my $result;
    local $@;
    eval { $result = system( 'dzil', 'perltidy' ); };
    my $res = $@;

    is( $result, 0, "perltidy works with a configuration setup!" )
        or diag explain {
        '$@'   => $res,
        '$?'   => $?,
        '$!'   => $!,
        result => $result,
        };
}

done_testing;

