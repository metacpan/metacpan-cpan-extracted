########################################################################
# housekeeping
########################################################################
use v5.36;

use Test::More;

BEGIN
{
    use File::Basename          qw( dirname );
    use File::Spec::Functions   qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', 'lib' );
}

# Tests the identity the Win32 same_owner filter compares against: the
# user SID from the process token, with no dependence on the
# environment.  Each level uses only what the levels above it proved.
#
# If the token cannot be read, the module falls back automatically to
# the login-name lookup (see $choose_sid; 21-choose_sid.t tests the
# selection with fake sources).  Levels 2-5 test the token path
# directly, so a failure here means the fallback is in use on that
# machine; level 6 tests the fallback source itself.
#
# Everything here is skipped off MSWin32.  Nothing in this file has been
# run on Windows yet.

use_ok 'File::Util::SecureDir'
or BAIL_OUT 'File::Util::SecureDir failed to load';

my $is_msw      = $^O eq 'MSWin32';
my $why_skip    = 'process-token SID needs MSWin32';
my $process_sid = do { no warnings 'once'; $File::Util::SecureDir::process_sid };

########################################################################
# level 0: the test hook exists on every platform
########################################################################

is ref $process_sid, 'CODE', 'process_sid hook is a coderef';

########################################################################
# level 1: the dependency loads
########################################################################

SKIP:
{
    $is_msw or skip $why_skip, 1;

    ok eval { require Win32::API; 1 }, 'Win32::API loads'
    or BAIL_OUT 'Win32::API is required for the process-token SID';
}

########################################################################
# level 2: the token can be read
########################################################################

my $sid = '';

SKIP:
{
    $is_msw or skip $why_skip, 1;

    $sid = eval { $process_sid->() } // '';

    ok length $sid, "process_sid returns a SID ($@)"
    or BAIL_OUT 'process_sid failed; see the alternative in the module comment';
}

########################################################################
# level 3: the SID is well formed (one property per test)
########################################################################

SKIP:
{
    $is_msw or skip $why_skip, 3;

    my ( $rev, $count ) = unpack 'C C', $sid;

    is $rev, 1, 'SID revision is 1';

    cmp_ok $count, '>=', 1, 'SID has at least one sub-authority';

    is length $sid, 8 + 4 * $count, 'SID length matches its sub-authority count';
}

########################################################################
# level 4: the SID is repeatable
########################################################################

SKIP:
{
    $is_msw or skip $why_skip, 1;

    my $again = eval { $process_sid->() } // '';

    is $again, $sid, 'process_sid returns the same SID on a second call';
}

########################################################################
# level 5: the SID does not depend on the environment (metadata driven)
########################################################################

my @env_casez
= (
    {
        name    => 'USERDOMAIN does not change the SID'
      , env     => { USERDOMAIN => 'NOT_A_DOMAIN' }
    }
  , {
        name    => 'USERNAME does not change the SID'
      , env     => { USERNAME => 'NOT_A_USER' }
    }
  , {
        name    => 'USERDNSDOMAIN does not change the SID'
      , env     => { USERDNSDOMAIN => 'not.a.domain' }
    }
  , {
        name    => 'COMPUTERNAME does not change the SID'
      , env     => { COMPUTERNAME => 'NOT_A_HOST' }
    }
);

SKIP:
{
    $is_msw or skip $why_skip, scalar @env_casez;

    for my $case ( @env_casez )
    {
        my ( $name, $env ) = @{ $case }{ qw( name env ) };

        local @ENV{ keys $env->%* } = values $env->%*;

        is eval { $process_sid->() } // '', $sid, $name;
    }
}

########################################################################
# level 6: the fallback source (login name, not the environment)
########################################################################

my $login_sid = do { no warnings 'once'; $File::Util::SecureDir::login_sid };

SKIP:
{
    $is_msw or skip $why_skip, 2;

    my $fallback = eval { $login_sid->() } // '';

    ok length $fallback, "login_sid returns a SID ($@)";

    my ( $rev, $count ) = unpack 'C C', $fallback;

    is length $fallback, 8 + 4 * ( $count // 0 ), 'login_sid SID length matches its sub-authority count';
}

done_testing;
