#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use POSIX qw(:termios_h);

eval { require IO::Pty };
plan skip_all => 'IO::Pty required for baud rate tests' if $@;

use IO::Stty;

sub fresh_pty {
    my $pty = IO::Pty->new or die "Cannot create pty: $!";
    my $slave = $pty->slave or die "Cannot get slave: $!";
    return ( $pty, $slave );
}

sub get_termios {
    my ($fh) = @_;
    my $t = POSIX::Termios->new;
    $t->getattr( fileno($fh) ) or die "getattr: $!";
    return $t;
}

# ── 1. Setting a valid baud rate via ospeed ───────────────────────────

subtest 'ospeed sets baud rate on pty' => sub {
    my ( $pty, $slave ) = fresh_pty();

    IO::Stty::stty( $slave, 'ospeed', '9600' );
    my $t = get_termios($slave);
    is( $t->getospeed, POSIX::B9600(), 'ospeed 9600 takes effect' );
};

subtest 'ispeed sets baud rate on pty' => sub {
    my ( $pty, $slave ) = fresh_pty();

    IO::Stty::stty( $slave, 'ispeed', '9600' );
    my $t = get_termios($slave);
    is( $t->getispeed, POSIX::B9600(), 'ispeed 9600 takes effect' );
};

subtest 'single-arg numeric sets both speeds' => sub {
    my ( $pty, $slave ) = fresh_pty();

    IO::Stty::stty( $slave, '9600' );
    my $t = get_termios($slave);
    is( $t->getospeed, POSIX::B9600(), 'single-arg 9600 sets ospeed' );
    is( $t->getispeed, POSIX::B9600(), 'single-arg 9600 sets ispeed' );
};

# ── 2. Invalid baud rate warns ────────────────────────────────────────

subtest 'unknown baud rate produces warning, does not die' => sub {
    my ( $pty, $slave ) = fresh_pty();

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $died = !eval {
        IO::Stty::stty( $slave, 'ospeed', '99999' );
        1;
    };

    ok( !$died,
        'stty does not die on unknown rate (old code dies via POSIX autoloader)' )
        or diag "died with: $@";

    is( scalar @warnings, 1, 'exactly one warning emitted' );
    like( $warnings[0] // '', qr/unknown baud rate '99999'/,
        'warning mentions the invalid rate' );
};

# ── 3. Regression guard: symbolic dereference in baud rate lookup ──────
#
# HISTORY: The ospeed/ispeed handlers originally used:
#
#     $ospeed = &{"POSIX::B" . shift(@parameters)};
#
# In theory, this pattern allows arbitrary code execution: an attacker
# who controls the stty arguments could pass any string and invoke an
# arbitrary function in the POSIX:: namespace.  However, all public
# releases (through 0.04) had 'use strict' enabled without a
# 'no strict "refs"' guard, so the symbolic dereference always died at
# runtime.  This means baud rate setting was completely broken in every
# released version — but the vulnerability was never exploitable as
# shipped.
#
# The fix replaced the symbolic dereference with a static %BAUD_RATES
# hash built at compile time from known constants.  This both fixes the
# bug (baud rates actually work now) and prevents the pattern from
# becoming exploitable if someone ever removed 'use strict'.
#
# This test guards against regression by planting a decoy function in
# the POSIX namespace and confirming it is never called.

subtest 'crafted baud rate cannot call arbitrary POSIX functions' => sub {
    my ( $pty, $slave ) = fresh_pty();

    # Record the speed before the attempt so we can verify it is unchanged.
    my $t_before = get_termios($slave);
    my $speed_before = $t_before->getospeed;

    # Plant a decoy in the POSIX namespace.  With the old vulnerable code,
    # stty($slave, 'ospeed', 'evil_test_probe') would execute:
    #     &{"POSIX::Bevil_test_probe"}
    # which calls this decoy.  The safe hash-based code never resolves the
    # name, so $decoy_called stays 0.
    #
    # There are two failure modes for the old code:
    #   1. Under 'use strict': dies with "Can't use string as a subroutine ref"
    #   2. Without strict refs: silently calls the decoy function
    # The fix must avoid both — no crash AND no arbitrary dispatch.
    my $decoy_called = 0;
    no warnings 'once';
    local *POSIX::Bevil_test_probe = sub { $decoy_called++; return 42 };

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $died = !eval {
        IO::Stty::stty( $slave, 'ospeed', 'evil_test_probe' );
        1;
    };

    ok( !$died,
        'stty with invalid rate does not die (old code croaks on symbolic deref under strict)' )
        or diag "died with: $@";

    ok( !$decoy_called,
        'decoy POSIX::Bevil_test_probe was not called (old code without strict would dispatch it)' );

    my $t_after = get_termios($slave);
    is( $t_after->getospeed, $speed_before,
        'ospeed unchanged after rejected rate' );

    ok( @warnings >= 1, 'warning emitted for unknown rate' );
    like( $warnings[0] // '', qr/unknown baud rate 'evil_test_probe'/,
        'warning names the rejected rate' );
};

done_testing;
