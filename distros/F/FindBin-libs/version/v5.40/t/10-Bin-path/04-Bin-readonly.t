package Testophile;
use v5.40;

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
use FindBin::Bin    qw( $Bin $Bin_l );

ok length( $Bin ),
    "\$Bin is non-empty: '$Bin'";

eval { $Bin = 'foobar'; 1 }
and fail   "\$Bin was modified to 'foobar'"
or  pass   "\$Bin is not modifiable: string value";

eval { $Bin = ''; 1 }
and fail   "\$Bin was modified to empty string"
or  pass   "\$Bin is not modifiable: empty string";

eval { $Bin = undef; 1 }
and fail   "\$Bin was modified to undef"
or  pass   "\$Bin is not modifiable: undef";

ok length( $Bin_l ),
    "\$Bin_l is non-empty: '$Bin_l'";

eval { $Bin_l = 'foobar'; 1 }
and fail   "\$Bin_l was modified to 'foobar'"
or  pass   "\$Bin_l is not modifiable: string value";

eval { $Bin_l = ''; 1 }
and fail   "\$Bin_l was modified to empty string"
or  pass   "\$Bin_l is not modifiable: empty string";

eval { $Bin_l = undef; 1 }
and fail   "\$Bin_l was modified to undef"
or  pass   "\$Bin_l is not modifiable: undef";

done_testing;
