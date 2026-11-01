package Testophile;
use v5.40;

# Test that FindBin::Bin sets $Bin and $Bin_l to the directory of $0
# when $0 is an absolute path.
# abs_path resolves symlinks; $Bin_l uses canon_dir on the raw $0 path.

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

BEGIN
{
    use Cwd qw( abs_path );
    $0 = abs_path $0;    # real physical absolute path of the test file
}

use Cwd                   qw( abs_path );
use File::Spec::Functions qw( catdir catpath file_name_is_absolute splitpath );
use Test::More;

use FindBin::Bin qw( $Bin $Bin_l );

{
    my ( $v,  $d  ) = ( splitpath abs_path( $0 ), '' )[0,1];
    my $exp_phys    = catpath $v, catdir( $d ), '';

    my ( $lv, $ld ) = ( splitpath $0, '' )[0,1];
    my $exp_log     = catpath $lv, FindBin::Bin::canon_dir( $ld ), '';

    ok  file_name_is_absolute( $Bin ),   "\$Bin is absolute for absolute \$0";
    ok  file_name_is_absolute( $Bin_l ), "\$Bin_l is absolute for absolute \$0";

    is  $Bin,   $exp_phys, "\$Bin is physical directory of absolute \$0";
    is  $Bin_l, $exp_log,  "\$Bin_l is logical directory of absolute \$0";
}

done_testing;
__END__
