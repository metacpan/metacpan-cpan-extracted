package Testophile;
use v5.40;

# Test that FindBin::Bin sets $Bin and $Bin_p correctly when $0 is
# 'interactive' (perl -d or debugger interactive session).
#
# $Bin_l = pwd()            -- logical CWD (symlinks preserved, like pwd -L)
# $Bin_p = abs_path(pwd())  -- physical CWD (symlinks resolved, like pwd -P)
# $Bin   = $Bin_p           -- defaults to physical path (abspath)

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

BEGIN { $0 = 'interactive' }

use File::Spec::Functions qw( file_name_is_absolute rel2abs );
use Test::More;

use FindBin::Bin qw( $Bin $Bin_l $Bin_p );

my $pwd = FindBin::Bin::pwd();

ok  file_name_is_absolute( $Bin ),   "\$Bin is absolute for 'interactive' invocation";
ok  file_name_is_absolute( $Bin_l ), "\$Bin_l is absolute for 'interactive' invocation";
ok  file_name_is_absolute( $Bin_p ), "\$Bin_p is absolute for 'interactive' invocation";

ok  -d $Bin,                          "\$Bin names an existing directory for 'interactive'";
ok  -d $Bin_l,                        "\$Bin_l names an existing directory for 'interactive'";

is  $Bin_l, $pwd,    "\$Bin_l eq pwd() for 'interactive' invocation";
is  $Bin,   $Bin_p,  "\$Bin eq \$Bin_p for 'interactive' invocation (abspath default)";

done_testing;
__END__
