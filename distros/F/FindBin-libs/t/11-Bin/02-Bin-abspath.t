package Testophile;
use v5.40;

# t/11-Bin/  is a real directory.
#
# Verify that:
#   - Default import: $Bin aliases $Bin_l (logical path)
#   - 'abspath' flag:  $Bin aliases $Bin_p (physical path)
#   - Bin() follows the same aliasing logic as $Bin

BEGIN
{
    use File::Basename        qw( dirname );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

use Test::More;
use FindBin::Bin qw( $Bin Bin $Bin_l Bin_l $Bin_p Bin_p );

is $Bin,  $Bin_l,  '$Bin defaults to $Bin_l (logical, no abspath flag)';
is Bin(), Bin_l(), 'Bin() defaults to Bin_l() (logical, no abspath flag)';

{
    package AbspathTest;
    our $Bin;
    FindBin::Bin->import( qw( $Bin abspath ) );

    Testophile::is( $Bin, $FindBin::Bin::Bin_p,
        '$Bin aliases $Bin_p with abspath flag' );
}

done_testing;
__END__
