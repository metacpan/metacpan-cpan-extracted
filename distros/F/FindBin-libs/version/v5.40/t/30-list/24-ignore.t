########################################################################
# housekeeping
########################################################################
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

use Cwd                   qw( abs_path );
use File::Basename        qw( dirname );
use File::Spec::Functions qw( catdir );
use Symbol                qw( qualify_to_ref );

########################################################################
# verify the ignore= import option excludes a named parent directory
# from the directory walk.
#
# Without ignore=, walking up from t/30-list/ finds both t/lib/ and the
# project-level lib/.  With ignore=<abs-path-to-t/>, t/lib/ is excluded
# but the project lib/ (a sibling of t/, not under it) is still found.

SKIP:
{
    require_ok 'FindBin::libs'
    or skip 'Failed require FindBin::libs', 3;

    # t/ directory, one level above this test file (t/30-list/).
    # abs_path resolves any trailing ".." so the ignore comparison works.
    my $t_dir = abs_path catdir dirname( $0 ), '..';

    # First import: no ignore -- t/lib/ should appear in the export.

    FindBin::libs->import
    (
        qw( base=lib export=libs_before_ignore )
    );

    my @before
    = @{ *{ qualify_to_ref 'libs_before_ignore' }{ ARRAY } // [] };

    my @t_lib_before = grep { m{ /t/lib$ }x } @before;

    ok @t_lib_before, "without ignore: t/lib found in walk";

    # Second import: ignore=<t-dir> -- t/lib/ must be absent; the
    # project-level lib/ (a sibling of t/, not under it) stays.

    FindBin::libs->import
    (
        'base=lib'
      , "ignore=$t_dir"
      , 'export=libs_after_ignore'
    );

    my @after
    = @{ *{ qualify_to_ref 'libs_after_ignore' }{ ARRAY } // [] };

    my @t_lib_after   = grep { m{ /t/lib$ }x } @after;
    my @proj_lib      = grep { m{ /lib$    }x && ! m{ /t/lib$ }x } @after;

    ok ! @t_lib_after, "with ignore=t-dir: t/lib excluded from walk";
    ok   @proj_lib,    "with ignore=t-dir: project lib still found";
}

done_testing;

__END__

=head1 NAME

24-ignore.t - verify FindBin::libs ignore= import option

=head1 DESCRIPTION

Tests the C<ignore=> import option, which accepts a comma-separated list
of absolute parent-directory paths to exclude from the directory walk.

The test exploits the existing directory layout: C<t/lib/> is reachable
from the C<t/30-list/> test directory, but C<ignore=<t-dir>> should
prevent it from appearing in the exported list while leaving the
project-level C<lib/> (a sibling of C<t/>, not under it) intact.

=head1 SEE ALSO

L<FindBin::libs>

=cut
