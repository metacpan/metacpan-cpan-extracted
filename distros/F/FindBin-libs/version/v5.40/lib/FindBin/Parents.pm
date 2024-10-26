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

    my $dirz
    = $path2dirz{ $path . $; . $assume_dir }
    ||= do
    {
        # treat non-existant paths as dir's, mainly for testing.

        my $is_dir  = $assume_dir || -d $path;

        my ( $vol, $dir ) = splitpath $path, $is_dir;

        # ditch the starting directory.

        my @dirz    = splitdir rel2abs canonpath $dir;

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
            ( '' => @dirz )
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
