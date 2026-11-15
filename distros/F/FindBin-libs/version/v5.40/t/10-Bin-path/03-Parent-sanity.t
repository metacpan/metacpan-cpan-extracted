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

my $madness = 'FindBin::Parents';
my @importz
= qw
(
    dir_paths
    clear_parent_cache
);

# '/foo/bar/bletch' does not exist: $assume_dir is required, 1 for a
# directory, '' for a file.

my $path    = '/foo/bar/bletch';
my $expect =
[
    qw
    (
        /foo/bar/bletch
        /foo/bar
        /foo
        /
    )
];

note "INC is:\n" => explain \@INC;

use_ok $madness => @importz;
can_ok __PACKAGE__, $_ for @importz;

SKIP:
{
    if( my @found = clear_parent_cache() )
    {
        fail 'clear_cached_parents returns data:';
        diag explain \@found;
    }
    else
    {
        pass 'clear_cached_parents returns empty.';
    }

    if( my @found = dir_paths( $path, 1 ) )
    {
        is_deeply \@found, $expect, "Parents of '/foo/bar/bletch', 1";
    }
    else
    {
        BAIL_OUT "parent_dirs returns empty list for /foo/bar/bletch";
    }

    if( my $found = dir_paths( $path, 1 ) )
    {
        is_deeply $found, $expect, "Parents of '/foo/bar/bletch', 1";
    }
    else
    {
        BAIL_OUT "parent_dirs returns empty scalar for /foo/bar/bletch";
    }

    shift @$expect;

    if( my @found = dir_paths( $path, '' ) )
    {
        is_deeply \@found, $expect, "Parents of '/foo/bar/bletch', ''";
    }
    else
    {
        fail 'Non-matching paths.';
        diag
            "\nExpect:\n", explain \$expect
          , "\nFound:\n" , explain \@found
        ;
    }

    if( my $found = dir_paths( $path, '' ) )
    {
        is_deeply $found, $expect, "Parents of '/foo/bar/bletch', ''";
    }
    else
    {
        fail "Non-matching paths.";
        diag
            "Expect:\n", explain $expect
          , "Found:\n" , explain $found
          ;
    }
}

done_testing;

__END__
