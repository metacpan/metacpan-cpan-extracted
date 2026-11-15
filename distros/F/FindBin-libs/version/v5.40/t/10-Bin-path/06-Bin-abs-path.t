package Testophile;
use v5.40;

# Test that FindBin::Bin sets $Bin and $Bin_l to the directory of $0
# when $0 is an absolute path.
# abs_path resolves symlinks; $Bin_l uses canon_dir on the raw $0 path.

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
