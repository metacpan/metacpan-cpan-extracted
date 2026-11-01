package Testophile;
use v5.40;

# Test that FindBin::Bin sets $Bin and $Bin_l correctly when $0 is a
# relative path.
#
#   $Bin   = $Bin_p = catpath( v, catdir(d), '' )
#                     where d comes from splitpath( abs_path($0) )
#                     abs_path uses the physical cwd for relative $0
#
#   $Bin_l = catpath( v, canon_dir(d), '' )
#            where d comes from splitpath( $0 )
#            canon_dir prepends pwd() (logical cwd) for relative paths

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

BEGIN
{
    use Cwd                   qw( abs_path cwd );
    use File::Spec::Functions qw( abs2rel );
    $0 = abs2rel( abs_path( $0 ), cwd() );    # real relative path from physical cwd
}

use Cwd                   qw( abs_path );
use File::Spec::Functions qw( catdir catpath file_name_is_absolute splitpath );
use Test::More;

use FindBin::Bin qw( $Bin $Bin_l );

{
    my ( $v, $d ) = ( splitpath abs_path( $0 ), '' )[0,1];
    my $exp_phys  = catpath $v, catdir( $d ), '';

    my ( $lv, $ld ) = ( splitpath $0, '' )[0,1];
    my $exp_log   = catpath $lv, FindBin::Bin::canon_dir( $ld ), '';

    ok  file_name_is_absolute( $Bin ),   "\$Bin is absolute for relative \$0";
    ok  file_name_is_absolute( $Bin_l ), "\$Bin_l is absolute for relative \$0";

    is  $Bin,   $exp_phys,
        "\$Bin eq physical-cwd/dir for relative \$0";

    is  $Bin_l, $exp_log,
        "\$Bin_l eq canon_dir(logical-cwd/dir) for relative \$0";
}

done_testing;
__END__
