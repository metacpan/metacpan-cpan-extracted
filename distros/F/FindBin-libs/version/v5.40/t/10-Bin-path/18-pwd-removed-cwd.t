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
# pwd() dies if the working directory cannot be resolved: getcwd
# returns undef after the working directory is removed.  abs_path
# cannot detect this, it returns a missing last component unchanged.
#
# $ENV{ PWD } is set to the removed directory, so the stale-PWD
# warning would be issued if the getcwd check were not made first.
#
# pwd() caches its first result.  With an absolute $0 loading
# FindBin::Bin does not call pwd(), so the first call is the one
# made in the removed directory.

my $start_d = getcwd;

$0          = rel2abs $0;

require_ok 'FindBin::Bin'
or BAIL_OUT 'Failed require FindBin::Bin';

SKIP:
{
    skip "Cannot remove the working directory on $^O", 4
    if $^O =~ m{ ^ (?: MSWin32 | VMS ) $ }x;

    my $tmpdir  = tempdir CLEANUP => 1;
    my $gone_d  = catdir $tmpdir, 'gone';

    mkdir $gone_d
    or die "mkdir '$gone_d': $!";

    chdir $gone_d
    or die "chdir '$gone_d': $!";

    rmdir $gone_d
    or skip "rmdir '$gone_d' (working directory): $!", 4;

    local $ENV{ PWD }   = $gone_d;

    my $cwd     = getcwd;
    my @warnz   = ();

    my $ok
    = do
    {
        local $SIG{ __WARN__ } = sub { push @warnz, @_ };

        eval { FindBin::Bin::pwd(); 1 }
    };

    my $error   = $@;

    chdir $start_d
    or die "chdir '$start_d': $!";

    ok ! defined $cwd, 'fixture: getcwd returns undef in a removed directory';

    ok ! $ok, 'Removed working directory: pwd() dies';

    like $error, qr{ ^ Unresolvable [ ] working [ ] directory: [ ] getcwd\(\) [ ] returned [ ] undef }x,
    'Removed working directory: error names the getcwd failure';

    is scalar @warnz, 0, 'Removed working directory: no stale-PWD warning';
}

done_testing;

__END__

=head1 NAME

18-pwd-removed-cwd.t - pwd() dies when the working directory is removed

=head1 DESCRIPTION

After the working directory is removed, C<getcwd> returns undef.
C<pwd()> must die with an error naming the C<getcwd> failure rather
than return undef, and must not first issue the stale-PWD warning.

Skipped on MSWin32 and VMS, which do not allow removing the working
directory.

=head1 SEE ALSO

L<FindBin::Bin>, F<16-chdir-builtin.t>, F<17-chdir-cwd.t>
