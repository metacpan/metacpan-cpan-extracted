package Testophile;
use v5.40;

# Test that FindBin::Bin sets $Bin and $Bin_c correctly when $0 is a
# relative path.  pwd() is prepended to produce an absolute path, then:
#
#   $Bin   = rel2abs( catdir(pwd, dir) )  -- canonpath of the joined path
#   $Bin_c = canon_dir( catdir(pwd, dir) ) -- stack-based '..' removal
#
# For paths with no '..' both are equal.  An absolute path with an
# embedded '..' shows the difference: rel2abs/canonpath leaves
# intermediate '..' in place; canon_dir resolves them via the stack.

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

use FindBin::Bin qw( $Bin $Bin_c );

{
    my ( $v, $d ) = splitpath 'this/is/relative/path.pl';
    my $raw       = catdir FindBin::Bin::pwd(), $d;

    ok  file_name_is_absolute( $Bin ),  "\$Bin is absolute for relative \$0";
    ok  file_name_is_absolute( $Bin_c ),"\$Bin_c is absolute for relative \$0";

    is  $Bin,   rel2abs( $raw ),
        "\$Bin eq rel2abs(catdir(pwd,dir)) for relative \$0";

    is  $Bin_c, FindBin::Bin::canon_dir( $raw ),
        "\$Bin_c eq canon_dir(catdir(pwd,dir)) for relative \$0";
}

done_testing;
__END__
