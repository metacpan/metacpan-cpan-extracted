package Testophile;
use v5.40;

# Test canon_dir behaviour when given empty, undef, or dot-only input.
# An empty or false dir argument must return pwd(); a bare '.' must
# collapse to pwd() as well since it carries no new information.

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

use File::Spec::Functions qw( catdir );
use Test::More;

use FindBin::Bin qw( $Bin $Bin_l );

my $cwd = FindBin::Bin::pwd();

{
    my $got = FindBin::Bin::canon_dir( '' );
    is $got, $cwd, "canon_dir('') returns pwd()";
}

{
    my $got = FindBin::Bin::canon_dir( undef );
    is $got, $cwd, "canon_dir(undef) returns pwd()";
}

{
    my $got = FindBin::Bin::canon_dir( '.' );
    is $got, $cwd, "canon_dir('.') collapses to pwd()";
}

{
    my $got = FindBin::Bin::canon_dir( catdir $cwd, '..' );
    my $exp = FindBin::Bin::canon_dir( catdir $cwd, '..', '.' );
    is $got, $exp, "canon_dir strips trailing dot after ..";
}

{
    my $deep = catdir $cwd, 'a', 'b', '..', 'c';
    my $flat = catdir $cwd, 'a', 'c';
    is FindBin::Bin::canon_dir( $deep ), $flat,
        "canon_dir resolves a/b/../c to a/c";
}

done_testing;
__END__
