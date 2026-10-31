########################################################################
# housekeeping
########################################################################
package FindBin::Parents  v0.1.0;
use v5.40;
use parent qw( Exporter );

use Carp            qw( croak   );
use List::Util      qw( reduce  );
use Storable        qw( dclone  );

use File::Spec::Functions
qw
(
    splitpath
    splitdir
    catdir
    catpath
    rel2abs
    canonpath
);

use FindBin::Bin    qw( canon_dir pwd );

########################################################################
# package variables and sanity checks 
########################################################################

our @EXPORT_OK  
= qw
(
    dir_paths
    clear_parent_cache
);

my %path2dirz   = ();

########################################################################
# utility subs
########################################################################

########################################################################
# exported
########################################################################

# avoid issues with repeated use on different paths.

sub clear_parent_cache()
{
    %path2dirz  = ();
}

sub dir_paths( $path, $assume_dir = 1 )
{
    $path
    or croak 'Bogus dir_paths: false path argument.';

    my $dir
    = $path eq 'pwd'
    ? pwd
    : $path
    ;

    my $dirz
    = $path2dirz{ $dir . $; . $assume_dir }
    ||= do
    {
        # $assume_dir treats non-existant paths as dir's,
        # mainly for testing.

        my $is_dir  = $assume_dir || -d $dir;

        my ( $vol, $dir_part ) = splitpath $dir, $is_dir;

        my @dirz    = splitdir canon_dir $dir_part;

        # fix for File::Spec::VMS missing the leading empty
        # string on a split. this can be removed once File::Spec
        # is fixed -- which appears to be never.

        my $tmp
        = $dirz[0]
        ? ''
        : shift @dirz
        ;

        [
            reverse
            map
            {
                catpath $vol => $_, ''
            }
            map
            {
                $tmp    = catdir $tmp, $_
            }
            (
                '' => @dirz[0..$#dirz]
            )
        ]
    };

    wantarray
    ?   @$dirz
    : [ @$dirz ]
}

1
__END__

=head1 NAME

FindBin::Parents - List parent dirs of the given path from curr to root.

=head1 SYNOPSIS

    use FindBin::Parents qw( dir_paths );

    # on *NIX (incl. OSX)
    # '/foo/bar/bim/bam' yields
    # /foo/bar/bim/bam
    # /foo/bar/bim
    # /foo/bar
    # /foo
    #
    # on VMS
    # 'Bletch$Blort:[foo.bar.bim.bam]' yields
    # Bletch$Blort:[foo.bar.bim.bam] 
    # Bletch$Blort:[foo.bar.bim] 
    # Bletch$Blort:[foo.bar] 
    # Bletch$Blort:[foo] 
    #
    # on MSW
    # 'z:/foo/bar/bim/bam' yields
    # z:/foo/bar/bim/bam
    # z:/foo/bar/bim 
    # z:/foo/bar 
    # z:/foo 
    #
    # $path is first passed through rel2abs and canonpath 
    # which should yield clean, absolute paths. 
    #
    # note that the return vlaue is context-sensitive:

    my $array_ref   = dir_paths $path;
    my @array       = dir_paths $path;

    # for any non-directory /foo/bar/bletch/blort, the final
    # 'blort' is dropped and the paths leading to it are returned:

    dir_paths $0;

    # /foo/bar/bletch   # parent dir of blort
    # /foo/bar
    # /foo

    # Note: non-existant paths are processed, but may require
    # an extra assume-dir argument to treat the argument as a 
    # directory (or not, no way to tell unless it exists, eh?).
    #
    # the default is true, these are equivalent:

    my @found       
    = dir_paths '/foo/bar/bletch/blort/non-existent';

    my @found       
    = dir_paths '/foo/bar/bletch/blort/non-existent', 1;

    # /foo/bar/bletch/blort/non-existant
    # /foo/bar/bletch/blort
    # /foo/bar/bletch
    # /foo/bar/bletch
    # /foo/bar
    # /foo

    # false value drops the last entry:

    my @found
    = dir_paths '/foo/bar/bletch/blort/non-existant', 0;

    # /foo/bar/bletch/blort
    # /foo/bar/bletch
    # /foo/bar/bletch
    # /foo/bar
    # /foo

    # The literal string 'pwd' is a shorthand: dir_paths resolves it
    # to FindBin::Bin::pwd (the logical CWD, symlinks preserved) before
    # the walk.  No separate import of pwd is required:

    use FindBin::Parents qw( dir_paths );

    my @above_cwd = dir_paths 'pwd';

    # If CWD is /home/user/projects/myapp:
    # /home/user/projects/myapp
    # /home/user/projects
    # /home/user
    # /home

    # This differs from passing $Bin_l or $Bin_p, which walk up from
    # the directory containing the running script ($0), not from CWD.
    # In most scripts those are the same; they diverge when the script
    # is invoked from a different directory or via a wrapper.

    # To resolve symlinks in the CWD before the walk, call pwd yourself
    # and pass the result through Cwd::abs_path:

    use FindBin::Bin    qw( pwd );
    use Cwd             qw( abs_path );

    my @above_real_cwd = dir_paths abs_path( pwd );

=head1 DESCRIPTION

C<FindBin::Parents> exports C<dir_paths>, which returns every ancestor
directory of the given path from the path itself up to the root, in
descending order (nearest first).

The canonical use is to inspect which directories C<FindBin::libs>
searched when looking for C<lib>, C<etc>, or other named trees:

    use FindBin::Bin    qw( $Bin_l $Bin_p );
    use FindBin::Parents qw( dir_paths );

    # show the logical walk (what FindBin::libs sees with noabspath)
    say for dir_paths $Bin_l;

    # show the physical walk (what FindBin::libs sees by default)
    say for dir_paths $Bin_p;

    # show the walk above CWD (independent of $0)
    say for dir_paths 'pwd';

Passing the literal string C<'pwd'> is a built-in shorthand: C<dir_paths>
calls C<FindBin::Bin::pwd> internally and uses the result as the starting
path.  This gives the logical CWD (symlinks preserved, like C<pwd -L>)
without requiring the caller to import C<pwd>.

C<'pwd'> is useful when the script is invoked from a directory different
from the one it lives in, or in interactive sessions and debugger
invocations where C<$Bin_l> and C<$Bin_p> already resolve to CWD anyway.
It produces a walk up from where the process is I<running>, whereas
C<$Bin_l> and C<$Bin_p> walk up from where the script I<lives>.

=head2 Caching

Results are cached by C<($path, $assume_dir)> pair.  Call
C<clear_parent_cache> to release the cache between repeated calls with
different CWD values (e.g. inside test suites that C<chdir>):

    use FindBin::Parents qw( dir_paths clear_parent_cache );

    chdir '/some/dir';
    clear_parent_cache;
    my @dirs = dir_paths pwd;

=head1 SEE ALSO

L<FindBin::Bin>, L<FindBin::libs>

