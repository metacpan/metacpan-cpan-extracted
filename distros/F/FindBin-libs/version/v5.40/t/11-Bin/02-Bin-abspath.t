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

########################################################################
# test the current module: $0 is */t/X/foo.t, the module is in */lib.
#
# lib must exist; if it is a symlink it must resolve to the lib next
# to the physical t directory, code outside the checkout is not
# loaded.  add it to @INC unless it is already there, or a blib is
# ("make test", "prove -b").

my $lib_d;

BEGIN
{
    use Cwd                   qw( abs_path );
    use File::Spec::Functions qw( catdir catpath rel2abs splitdir splitpath );
    use List::Util            qw( first );

    my ( $vol, $dir )   = splitpath rel2abs $0;
    my @dirz            = splitdir $dir;

    pop @dirz
    while @dirz && $dirz[-1] ne 't';

    @dirz
    or die "Bogus test path: no 't' directory in '$0'.\n";

    my $t_d     = catpath $vol, ( catdir @dirz ), '';

    $dirz[-1]   = 'lib';
    $lib_d      = catpath $vol, ( catdir @dirz ), '';

    -d $lib_d
    or die "Bogus test path: '$lib_d' from '$0' is not a directory.\n";

    if( -l $lib_d )
    {
        my ( $t_vol, $t_phys )  = splitpath abs_path( $t_d ), 1;
        my @t_dirz              = splitdir $t_phys;

        $t_dirz[-1] = 'lib';

        my $expect  = catpath $t_vol, ( catdir @t_dirz ), '';
        my $found   = abs_path $lib_d;

        $found eq $expect
        or die "Bogus lib: symlink '$lib_d' resolves to '$found', "
        . "expected '$expect' next to the test directory.\n";
    }

    first
    {
        ! ref $_
        and
        (
            m{ (?: ^ | / ) blib / }x
            or rel2abs( $_ ) eq $lib_d
        )
    }
    @INC
    or unshift @INC, $lib_d;
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
