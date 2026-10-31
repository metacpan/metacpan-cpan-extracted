package Testophile;
use v5.40;

# t/11-Bin/  is a real directory.
# t/12-Bin_l is a symlink to t/11-Bin.
#
# $Bin  defaults to $Bin_p (physical path, abspath, like pwd -P).
# $Bin_p uses Cwd::abs_path -- resolves all symlinks.
#
# Running from t/11-Bin/ (real dir): $Bin_p == $Bin_l (no symlinks to resolve).
# Running from t/12-Bin_l/ (symlink): $Bin_p != $Bin_l -- $Bin_p resolves
# the symlink to t/11-Bin while $Bin_l keeps the logical t/12-Bin_l path.

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

use Test::More;

use FindBin::Bin qw( $Bin $Bin_p );

is $Bin, $Bin_p, "\$Bin eq \$Bin_p: '$Bin'";

done_testing;
__END__
