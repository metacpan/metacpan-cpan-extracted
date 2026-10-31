package Testophile;
use v5.40;

# Test that FindBin::Bin sets $Bin and $Bin_l correctly when $0 is a
# relative path.  pwd() is prepended to produce an absolute path, then:
#
#   $Bin   = $Bin_p = abs_path( catdir(pwd, dir) )  -- physical (abspath default)
#                     (for non-existent test paths abs_path fails and falls
#                      back to the raw joined path, same value as rel2abs)
#   $Bin_l = canon_dir( catdir(pwd, dir) )           -- stack-based '..' removal
#
# For paths with no '..' both are equal.  An absolute path with an
# embedded '..' shows the difference: abs_path/rel2abs leave intermediate
# '..' segments in place; canon_dir resolves them via the stack.

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

BEGIN { $0 = 'this/is/relative/path.pl' }

use File::Spec::Functions qw( catdir catpath file_name_is_absolute rel2abs splitpath );
use Test::More;

use FindBin::Bin qw( $Bin $Bin_l );

{
    my ( $v, $d ) = splitpath 'this/is/relative/path.pl';
    my $raw       = catdir FindBin::Bin::pwd(), $d;

    ok  file_name_is_absolute( $Bin ),  "\$Bin is absolute for relative \$0";
    ok  file_name_is_absolute( $Bin_l ),"\$Bin_l is absolute for relative \$0";

    is  $Bin,   rel2abs( $raw ),
        "\$Bin eq abs_path(catdir(pwd,dir)) for relative \$0 (fallback matches rel2abs)";

    is  $Bin_l, FindBin::Bin::canon_dir( $raw ),
        "\$Bin_l eq canon_dir(catdir(pwd,dir)) for relative \$0";
}

done_testing;
__END__
