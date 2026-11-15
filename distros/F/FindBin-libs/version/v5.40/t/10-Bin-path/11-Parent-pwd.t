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

use_ok $madness => @importz;
can_ok __PACKAGE__, $_ for @importz;

SKIP:
{
    # FindBin::Bin is already loaded as a dependency of FindBin::Parents.
    # pwd() caches the startup CWD via a state variable (like "pwd -L").
    # Calling it by full package name avoids a compile-time 'use' that
    # would fail when the lib is not yet in @INC during 'perl -wc'.

    my $cwd = FindBin::Bin::pwd();

    my @via_sentinel;

    if( @via_sentinel = dir_paths( 'pwd' ) )
    {
        ok 1, "'pwd' sentinel returns a list";
    }
    else
    {
        BAIL_OUT "'pwd' sentinel returns empty list";
    }

    is $via_sentinel[0], $cwd,
        "first element is FindBin::Bin::pwd()";

    # scalar context returns the same content as an arrayref

    my $ref_sentinel;

    if( $ref_sentinel = dir_paths( 'pwd' ) )
    {
        is_deeply $ref_sentinel, \@via_sentinel,
            "scalar context returns arrayref matching list context";
    }
    else
    {
        BAIL_OUT "'pwd' sentinel returns false in scalar context";
    }

    # sentinel must be equivalent to passing pwd() as a literal path

    my @via_call = dir_paths( $cwd );

    is_deeply \@via_sentinel, \@via_call,
        "'pwd' sentinel matches dir_paths( pwd() )";

    # clear_parent_cache resets the dir_paths memo-table but does not
    # affect pwd() (which uses a state variable).  Result must be stable.

    clear_parent_cache();

    my @after_clear = dir_paths( 'pwd' );

    is_deeply \@after_clear, \@via_sentinel,
        "result is stable after clear_parent_cache";

    is $after_clear[0], $cwd,
        "first element still equals FindBin::Bin::pwd() after clear";
}

done_testing;

__END__
