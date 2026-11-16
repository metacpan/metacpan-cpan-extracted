########################################################################
# housekeeping
########################################################################
use v5.36;

use File::Temp  qw( tempdir );
use Test::More;

BEGIN
{
    use File::Basename          qw( dirname );
    use File::Spec::Functions   qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', 'lib' );
}

# Depends on 30-win32-process-sid.t: the SID the filter compares
# against.  The filter is set once per process, so this file ends in
# same_owner.
#
# A process running elevated creates directories owned by the
# Administrators group, not by its own SID; same_owner accepts
# Administrators and SYSTEM as it accepts root, so this holds either way.
#
# Skipped off MSWin32; not yet run on Windows.

use File::Util::SecureDir qw( filter=same_owner );

my $is_msw  = $^O eq 'MSWin32';
my $secure  = File::Util::SecureDir->new;

SKIP:
{
    $is_msw or skip 'Win32 owner SIDs need MSWin32', 1;

    my $dir     = tempdir( CLEANUP => 1 );
    my @clean   = $secure->filter_dirs( $dir );

    is scalar @clean, 1, 'same_owner: directory created by this process is accepted';
}

done_testing;
