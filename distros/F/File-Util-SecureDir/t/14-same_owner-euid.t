########################################################################
# housekeeping
########################################################################
use v5.36;

use File::Temp  qw( tempdir );
use List::Util  qw( first   );
use Test::More;

BEGIN
{
    use File::Basename          qw( dirname );
    use File::Spec::Functions   qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', 'lib' );
}

# same_owner compares the directory owner with the EFFECTIVE uid ($>),
# not the real uid ($<): under sudo or a setuid program the real uid is
# the invoker.  The filter is set once per process, so this file ends in
# same_owner.

use File::Util::SecureDir qw( filter=same_owner );

my $secure  = File::Util::SecureDir->new;
my $accepts
= sub( $dir )
{
    my @clean = $secure->filter_dirs( $dir );

    @clean == 1
};

my $is_msw  = $^O eq 'MSWin32';
my $is_root = ! $is_msw && $< == 0 && $> == 0;

########################################################################
# filter selection
########################################################################

is $secure->filter, 'same_owner', 'same_owner: filter selected';

########################################################################
# owner is the EUID
########################################################################

SKIP:
{
    $is_msw and skip 'uid ownership is not tested on MSWin32', 1;

    my $dir = tempdir( CLEANUP => 1 );

    chmod 0700, $dir;

    ok $accepts->( $dir ), 'same_owner: directory owned by the EUID is accepted';
}

########################################################################
# owner is another non-root user
########################################################################

SKIP:
{
    $is_msw and skip 'uid ownership is not tested on MSWin32', 1;

    # any directory with no group/other write bit, not owned by root
    # or by the EUID, so only the owner check can reject it.

    my $foreign
    = first
    {
        my @st = stat $_;

        @st && -d _ && $st[4] != 0 && $st[4] != $> && ! ( $st[2] & 0022 )
    }
    map { glob $_ } qw( /home/* /var/* /usr/* /srv/* /* );

    $foreign or skip 'no directory owned by another non-root user', 1;

    ok ! $accepts->( $foreign ), "same_owner: directory owned by another user is rejected ($foreign)";
}

########################################################################
# EUID and real uid differ (needs root to drop the EUID)
########################################################################

SKIP:
{
    $is_root or skip 'needs root to give the process a different EUID', 2;

    my $nobody = getpwnam( 'nobody' );

    defined $nobody or skip 'no user nobody', 2;

    my $dir = tempdir( CLEANUP => 1 );

    chmod 0755, $dir;
    chown $nobody, -1, $dir;

    {
        local $> = $nobody;

        ok $accepts->( $dir ), 'same_owner: directory owned by the EUID is accepted when the real uid differs';
    }

    # back at EUID 0 the same directory belongs to another user.

    ok ! $accepts->( $dir ), 'same_owner: directory owned by another user is rejected for an EUID of root';
}

done_testing;
