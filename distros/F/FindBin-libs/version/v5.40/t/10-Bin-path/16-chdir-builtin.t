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

use Cwd                   qw( getcwd );
use File::Spec::Functions qw( catdir rel2abs );
use File::Temp            qw( tempdir );
use Test::More;

########################################################################
# a builtin chdir does not update $ENV{ PWD }; pwd() detects the stale
# $PWD by comparing its inode with '.' and uses getcwd, with a warning.
#
# pwd() caches its first result.  With an absolute $0 loading
# FindBin::Bin does not call pwd(), so the first call is the one
# made after the chdir.  17-chdir-cwd.t tests Cwd::chdir, which does
# update $PWD.

my $start_d = getcwd;

$0          = rel2abs $0;

require_ok 'FindBin::Bin'
or BAIL_OUT 'Failed require FindBin::Bin';

SKIP:
{
    skip "No inode check of \$PWD on $^O", 4
    if $^O =~ m{ ^ (?: MSWin32 | VMS ) $ }x;

    # start with a valid $PWD, as a shell would.

    local $ENV{ PWD }   = $start_d;

    my $tmpdir  = tempdir CLEANUP => 1;

    my $pwd0    = $ENV{ PWD };

    chdir $tmpdir
    or die "chdir '$tmpdir': $!";

    my $cwd     = getcwd;

    my @warnz   = ();

    my $pwd1
    = do
    {
        local $SIG{ __WARN__ } = sub { push @warnz, @_ };

        FindBin::Bin::pwd()
    };

    chdir $start_d
    or die "chdir '$start_d': $!";

    is $ENV{ PWD }, $pwd0, 'Builtin chdir leaves $ENV{ PWD } unchanged';

    isnt $pwd1, $pwd0, "Correctly detected mismatched PWD and '.' by resolving inode";

    is $pwd1, $cwd, 'Stale PWD: pwd() returns getcwd';

    is scalar @warnz, 1, 'Stale PWD generates one warning';
}

done_testing;

__END__

=head1 NAME

16-chdir-builtin.t - pwd() after a builtin chdir leaves $PWD stale

=head1 DESCRIPTION

A builtin C<chdir> does not update C<$ENV{ PWD }>.  After a C<chdir>
into a one-time directory, C<pwd()> must detect that C<$PWD> no longer
matches the inode of C<'.'>, and return C<getcwd> instead of the stale
C<$PWD>, with one warning.

Skipped on MSWin32 and VMS, where C<pwd()> does not use C<$PWD>.

=head1 SEE ALSO

L<FindBin::Bin>, F<17-chdir-cwd.t>
