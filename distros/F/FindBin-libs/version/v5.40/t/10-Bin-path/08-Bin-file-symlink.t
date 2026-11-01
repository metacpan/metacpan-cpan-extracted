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

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
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
