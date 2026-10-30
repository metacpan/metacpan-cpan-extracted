package Testophile;
use v5.40;

# t/11-Bin/  is a real directory.
# t/12-Bin_l is a symlink to t/11-Bin.
#
# $Bin  defaults to $Bin_l (logical path, like pwd -L).
# $Bin_l uses canon_dir  -- stack-based '..' removal, symlinks preserved.
#
# For paths without '..', both are identical.  Running the same test
# from a symlinked directory (t/12-Bin_l/) should also keep them equal:
# neither $Bin nor $Bin_l resolves directory symlinks.

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

use Test::More;

use FindBin::Bin qw( $Bin $Bin_l );

is $Bin, $Bin_l, "\$Bin eq \$Bin_l: '$Bin'";

done_testing;
__END__
