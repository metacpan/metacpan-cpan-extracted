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

# pass the lib to child processes only if this test added it: with
# "prove -b" or "make test" they inherit blib via PERL5LIB.

my @inc_argz    = map { "-I$_" } grep { $_ eq $lib_d } @INC;

use Cwd                   qw( abs_path );
use File::Path            qw( make_path );
use File::Spec::Functions qw( catdir catfile catpath splitpath );
use File::Temp            qw( tempdir );
use Test::More;

########################################################################
# driver script written into the real bin dir and run via the symlinked
# path.  uses separate export= names to capture abspath and noabspath
# results independently.
#
# "nofail" suppresses any carp when directories are not found under
# ancestors near the filesystem root.

my $driver_code = <<'END_DRIVER';
package TestDriver;
use v5.40;
no warnings 'once';
use FindBin::libs;

FindBin::libs->import( qw( abspath   export=abs_found   nofail ) );
FindBin::libs->import( qw( noabspath export=noabs_found nofail ) );

print "abs:$_\n"   for @TestDriver::abs_found;
print "noabs:$_\n" for @TestDriver::noabs_found;
END_DRIVER

########################################################################

SKIP:
{
    $^O eq 'MSWin32'
    and skip 'No directory symlinks on MSWin32', 6;

    require_ok 'FindBin::libs'
    or skip 'Failed require FindBin::libs', 5;

    # Directory layout:
    #   $tmp/projects/app/bin/  <- physical bin ($Bin_p points here)
    #   $tmp/projects/lib/      <- found only by abspath walk
    #   $tmp/home/lib/          <- found only by noabspath walk
    #   $tmp/home/app           <- symlink -> ../projects/app
    #
    # Running the driver as $tmp/home/app/bin/driver.pl sets:
    #   $Bin_l = $tmp/home/app/bin     (logical, symlink preserved)
    #   $Bin_p = $tmp/projects/app/bin (physical, symlink resolved)

    my $tmp = tempdir CLEANUP => 1;
    my ( $vol ) = splitpath $tmp, 1;

    my $real_bin  = catdir $tmp, 'projects', 'app', 'bin';
    my $phys_lib  = catdir $tmp, 'projects', 'lib';
    my $home_dir  = catdir $tmp, 'home';
    my $logic_lib = catdir $tmp, 'home', 'lib';
    my $sym_app   = catdir $tmp, 'home', 'app';

    make_path $real_bin, $phys_lib, $home_dir, $logic_lib
    or skip 'make_path failed for temp tree', 5;

    # symlink: home/app -> ../projects/app
    symlink catdir( '..', 'projects', 'app' ), $sym_app
    or skip "Cannot create symlink: $!", 5;

    my $logic_bin    = catdir $sym_app,   'bin';
    my $driver_path  = catfile $logic_bin, 'driver.pl';
    my $real_driver  = catfile $real_bin,  'driver.pl';

    open my $wfh, '>', $real_driver
    or skip "Cannot write driver: $!", 5;

    print $wfh $driver_code;
    close $wfh;

    open my $rfh, '-|', $^X, @inc_argz, $driver_path
    or skip "Cannot run driver: $!", 5;

    chomp( my @lines = <$rfh> );
    close $rfh;

    my @abs_found
    = map  { ( my $p = $_ ) =~ s{^abs:}{}; $p }
      grep { /^abs:/   }
      @lines;

    my @noabs_found
    = map  { ( my $p = $_ ) =~ s{^noabs:}{}; $p }
      grep { /^noabs:/ }
      @lines;

    # abs_path resolves any symlinks in the tempdir prefix itself
    # (e.g. /tmp -> /private/tmp on macOS).
    my $abs_phys  = abs_path $phys_lib;
    my $abs_logic = abs_path $logic_lib;

    ok   grep( { $_ eq $abs_phys  } @abs_found   ),
        "abspath: finds projects/lib";

    ok ! grep( { $_ eq $abs_logic } @abs_found   ),
        "abspath: does not find home/lib";

    ok   grep( { $_ eq $abs_logic } @noabs_found ),
        "noabspath: finds home/lib";

    ok ! grep( { $_ eq $abs_phys  } @noabs_found ),
        "noabspath: does not find projects/lib";

    my @unexpected = grep { ! /^(?:abs|noabs):/ } @lines;
    ok ! @unexpected, "driver produced no unexpected output lines";
}

done_testing;

__END__

=head1 NAME

25-libs-abspath.t - verify FindBin::libs abspath/noabspath walk-root selection

=head1 DESCRIPTION

Tests that C<FindBin::libs> respects the C<abspath>/C<noabspath> import
option when choosing between C<$Bin_p> (physical, symlinks resolved) and
C<$Bin_l> (logical, symlinks preserved) as the directory-walk root.

A temporary directory tree is built:

    $tmp/projects/app/bin/   <- physical bin
    $tmp/projects/lib/       <- found by abspath walk only
    $tmp/home/lib/           <- found by noabspath walk only
    $tmp/home/app            <- symlink -> ../projects/app

The driver script is written to C<$tmp/projects/app/bin/driver.pl> and
invoked as C<$tmp/home/app/bin/driver.pl> (through the symlink).  This
produces C<$Bin_l = $tmp/home/app/bin> and C<$Bin_p =
$tmp/projects/app/bin>, causing each walk to find a distinct C<lib/>
subtree.

The test is skipped on MSWin32, which does not support directory
symlinks in the same way.

=head1 SEE ALSO

L<FindBin::libs>, L<FindBin::Bin>

=cut
