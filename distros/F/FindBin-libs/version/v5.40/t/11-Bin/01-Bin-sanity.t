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

use FindBin::Bin qw( $Bin $Bin_p );

is $Bin, $Bin_p, "\$Bin eq \$Bin_p: '$Bin'";

done_testing;
__END__
