package Testophile;
use v5.40;

# Verify $Bin_l and $Bin_p when the executable ($0) is a file symlink.
# Run via the symlink at t/10-Bin-path/09-Bin-symlink-exec.t, which
# points to this file in version/v5.40/t/10-Bin-path/.
#
# abs_path follows all symlinks, so $Bin_p is the real file's directory,
# not the directory that contains the symlink.  $Bin_l uses canon_dir
# (logical cwd) on the raw $0 path, so it stays in the symlink directory.
#
# If $0 is not a symlink (direct run from version/v5.40/), the
# symlink assertions are skipped.

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

use Cwd                   qw( abs_path );
use File::Spec::Functions qw( catdir catpath splitpath );
use Test::More;
use FindBin::Bin          qw( $Bin_l $Bin_p );

SKIP:
{
    skip '$0 is not a symlink; run via t/10-Bin-path/ for symlink coverage', 4
        unless -l $0;

    my ( $rv, $rd ) = ( splitpath abs_path( $0 ), '' )[0,1];
    my $real_dir    = catpath $rv, catdir( $rd ), '';

    my ( $lv, $ld ) = ( splitpath $0, '' )[0,1];
    my $exp_log     = catpath $lv, FindBin::Bin::canon_dir( $ld ), '';

    isnt $Bin_p,    $exp_log,  '$Bin_p (real file dir) differs from $Bin_l (symlink dir)';
    is   $Bin_p,    $real_dir, '$Bin_p resolves to real file directory via abs_path';
    is   $Bin_l,    $exp_log,  '$Bin_l is the symlink logical directory';
    isnt $Bin_l,    $real_dir, '$Bin_l is not the real file directory';
}

done_testing;
__END__
