package Testophile;
use v5.40;

# Verify $Bin_l and $Bin_p behavior when $0 is a file-level symlink.
# FindBin::Bin uses abs_path, which follows file-level symlinks to the
# real file.  $Bin_p is the directory of the real file; $Bin_l is the
# directory of the symlink (logical, from canon_dir on the raw $0 path).
#
# /link/dir/script.pl -> /real/bin/script.pl  (file symlink)
#
#   $Bin_l => /link/dir   (logical: dir of $0 as given)
#   $Bin_p => /real/bin   (physical: abs_path follows the file symlink)

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
    use File::Spec::Functions qw( catdir catfile );
    use File::Temp            qw( tempdir );
    use File::Path            qw( make_path );

    my $tmp         = tempdir CLEANUP => 1;
    our $symlink_dir = catdir $tmp, 'link';
    our $real_bin    = catdir $tmp, 'real', 'bin';

    make_path $symlink_dir;
    make_path $real_bin;

    my $real_script = catfile $real_bin, 'script.pl';
    open my $fh, '>', $real_script
    or die "Cannot create '$real_script': $!";
    close $fh;

    my $link_script = catfile $symlink_dir, 'script.pl';

    symlink $real_script, $link_script
    or die "Cannot create symlink '$link_script' -> '$real_script': $!";

    $0 = $link_script;
}

use Test::More;
use FindBin::Bin qw( $Bin_l $Bin_p );

our ( $symlink_dir, $real_bin );

is   $Bin_l, $symlink_dir, '$Bin_l is the symlink directory';
is   $Bin_p, $real_bin,    '$Bin_p is the real file directory (abs_path follows file symlinks)';

isnt $Bin_p, $symlink_dir, '$Bin_p is not the symlink directory';

done_testing;
__END__
