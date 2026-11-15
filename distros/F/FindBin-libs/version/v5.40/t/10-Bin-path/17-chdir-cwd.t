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

use Cwd                   qw( abs_path getcwd );
use File::Spec::Functions qw( catdir rel2abs );
use File::Temp            qw( tempdir );
use Test::More;

########################################################################
# Cwd::chdir updates $ENV{ PWD }; pwd() finds $PWD matches the inode
# of '.' and returns $PWD, symlinks preserved, without a warning.
#
# The chdir is into a symlink, so the logical $PWD and the physical
# getcwd differ: pwd() returning the symlink path shows that $PWD was
# used, not getcwd.
#
# pwd() caches its first result.  With an absolute $0 loading
# FindBin::Bin does not call pwd(), so the first call is the one
# made after the chdir.  16-chdir-builtin.t tests the builtin chdir,
# which does not update $PWD.

my $start_d = getcwd;

$0          = rel2abs $0;

require_ok 'FindBin::Bin'
or BAIL_OUT 'Failed require FindBin::Bin';

SKIP:
{
    skip "No inode check of \$PWD on $^O", 5
    if $^O =~ m{ ^ (?: MSWin32 | VMS ) $ }x;

    local $ENV{ PWD }   = $start_d;

    my $tmpdir  = tempdir CLEANUP => 1;
    my $real_d  = catdir $tmpdir, 'real';
    my $link_d  = catdir $tmpdir, 'link';

    mkdir $real_d
    or die "mkdir '$real_d': $!";

    symlink $real_d, $link_d
    or skip "symlink '$link_d': $!", 5;

    isnt abs_path( $link_d ), $link_d, 'fixture: symlink path differs from physical path';

    Cwd::chdir $link_d
    or die "chdir '$link_d': $!";

    my $pwd0    = $ENV{ PWD };

    my @warnz   = ();

    my $pwd1
    = do
    {
        local $SIG{ __WARN__ } = sub { push @warnz, @_ };

        FindBin::Bin::pwd()
    };

    chdir $start_d
    or die "chdir '$start_d': $!";

    is $pwd0, $link_d, 'Cwd::chdir updates $ENV{ PWD }';

    is $pwd1, $pwd0, "Correctly detected matching PWD and '.' by resolving inode";

    isnt $pwd1, abs_path( $link_d ), 'Valid PWD: pwd() preserves the symlink';

    is scalar @warnz, 0, 'Valid PWD generates no warning';
}

done_testing;

__END__

=head1 NAME

17-chdir-cwd.t - pwd() after Cwd::chdir keeps $PWD valid

=head1 DESCRIPTION

C<Cwd::chdir> updates C<$ENV{ PWD }>.  After a C<Cwd::chdir> into a
symlink to a one-time directory, C<pwd()> must find that C<$PWD>
matches the inode of C<'.'> and return C<$PWD>, with the symlink
preserved, and without a warning.

Skipped on MSWin32 and VMS, where C<pwd()> does not use C<$PWD>.

=head1 SEE ALSO

L<FindBin::Bin>, F<16-chdir-builtin.t>
