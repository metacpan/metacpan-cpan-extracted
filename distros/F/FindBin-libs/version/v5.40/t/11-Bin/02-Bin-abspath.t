package Testophile;
use v5.40;

# t/11-Bin/  is a real directory.
#
# Verify that:
#   - Default import:      $Bin aliases $Bin_p (physical path, abspath)
#   - 'abspath' flag:      $Bin aliases $Bin_p (physical, explicit -- same as default)
#   - 'noabspath' flag:    $Bin aliases $Bin_l (logical path)
#   - Bin() follows the same aliasing logic as $Bin
#
# This behavior matches FindBin::libs, which also defaults to abspath
# and accepts 'noabspath' to select the logical path.

BEGIN
{
    use File::Basename        qw( dirname );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

use Test::More;
use FindBin::Bin qw( $Bin Bin $Bin_l Bin_l $Bin_p Bin_p );

is $Bin,  $Bin_p,  '$Bin defaults to $Bin_p (physical, abspath)';
is Bin(), Bin_p(), 'Bin() defaults to Bin_p() (physical, abspath)';

{
    package AbspathTest;
    our ( $Bin );
    FindBin::Bin->import( qw( $Bin abspath ) );

    Testophile::is( $Bin, $FindBin::Bin::Bin_p,
        '$Bin aliases $Bin_p with explicit abspath flag' );
}

{
    package NoAbspathTest;
    our ( $Bin );
    FindBin::Bin->import( qw( $Bin noabspath ) );

    Testophile::is( $Bin, $FindBin::Bin::Bin_l,
        '$Bin aliases $Bin_l with noabspath flag' );
}

{
    package NoAbspathSubTest;
    our ( $Bin );
    FindBin::Bin->import( qw( $Bin Bin noabspath ) );

    Testophile::is( $Bin, $FindBin::Bin::Bin_l,
        '$Bin aliases $Bin_l with noabspath flag (sub+scalar)' );

    Testophile::is( Bin(), $FindBin::Bin::Bin_l,
        'Bin() aliases Bin_l() with noabspath flag' );
}

done_testing;
__END__
