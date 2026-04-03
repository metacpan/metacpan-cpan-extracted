#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use POSIX qw(:termios_h);

eval { require IO::Pty };
plan skip_all => 'IO::Pty required for terminal tests' if $@;

use IO::Stty;

sub fresh_pty {
    my $pty   = IO::Pty->new or die "Cannot create pty: $!";
    my $slave = $pty->slave  or die "Cannot get slave: $!";
    return ( $pty, $slave );
}

sub get_termios {
    my ($fh) = @_;
    my $t = POSIX::Termios->new;
    $t->getattr( fileno($fh) ) or die "getattr: $!";
    return $t;
}

# ── Single numeric arg sets baud rate ────────────────────────────────
# This was broken: the if/elsif chain had a separate if/else for -g
# that fell through and overwrote @parameters for numeric args.

subtest 'single numeric arg sets ispeed and ospeed' => sub {
    my ( $pty, $slave ) = fresh_pty();

    # Capture warnings — before the fix, this produced
    # "IO::Stty::stty passed invalid parameter '9600'"
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    IO::Stty::stty( $slave, '9600' );

    is( scalar @warnings, 0, 'no warnings from numeric baud rate arg' )
      or diag "Got warnings: @warnings";

    my $t = get_termios($slave);
    is( $t->getospeed, POSIX::B9600(), 'ospeed set to B9600' );
    is( $t->getispeed, POSIX::B9600(), 'ispeed set to B9600' );
};

# ── -g save/restore round-trip ───────────────────────────────────────

subtest '-g save and restore round-trip' => sub {
    my ( $pty, $slave ) = fresh_pty();

    # Save current settings
    my $saved = IO::Stty::stty( $slave, '-g' );
    ok( defined $saved, '-g returns defined value' );

    my @parts = split /:/, $saved;
    is( scalar @parts, 17, '-g output has 17 colon-separated fields' );

    # Change something
    IO::Stty::stty( $slave, '-echo' );
    my $t = get_termios($slave);
    ok( !( $t->getlflag & ECHO ), 'echo disabled' );

    # Restore
    IO::Stty::stty( $slave, $saved );
    $t = get_termios($slave);

    # The restored lflag should match what was saved
    is( $t->getlflag, $parts[3], 'lflag restored to saved value' );
};

# ── -a output ────────────────────────────────────────────────────────

subtest '-a returns human-readable output' => sub {
    my ( $pty, $slave ) = fresh_pty();

    my $output = IO::Stty::stty( $slave, '-a' );
    ok( defined $output, '-a returns defined value' );
    like( $output, qr/speed \d+ baud/, 'contains speed line' );
    like( $output, qr/echo/,           'contains echo setting' );
};

# ── -v returns version ───────────────────────────────────────────────

subtest '-v returns version' => sub {
    my ( $pty, $slave ) = fresh_pty();

    my $ver = IO::Stty::stty( $slave, '-v' );
    is( $ver, $IO::Stty::VERSION . "\n", '-v returns VERSION' );
};

subtest '--version returns version' => sub {
    my ( $pty, $slave ) = fresh_pty();

    my $ver = IO::Stty::stty( $slave, '--version' );
    is( $ver, $IO::Stty::VERSION . "\n", '--version returns VERSION' );
};

subtest 'version (bare) returns version' => sub {
    my ( $pty, $slave ) = fresh_pty();

    my $ver = IO::Stty::stty( $slave, 'version' );
    is( $ver, $IO::Stty::VERSION . "\n", 'bare version returns VERSION' );
};

# ── speed query ──────────────────────────────────────────────────────

subtest 'speed returns output baud rate' => sub {
    my ( $pty, $slave ) = fresh_pty();

    IO::Stty::stty( $slave, '9600' );
    my $speed = IO::Stty::stty( $slave, 'speed' );
    is( $speed, "9600\n", 'speed returns symbolic baud rate' );
};

subtest 'speed with unknown rate returns raw numeric' => sub {
    my ( $pty, $slave ) = fresh_pty();

    # Just verify speed returns something reasonable for default pty speed
    my $speed = IO::Stty::stty( $slave, 'speed' );
    ok( defined $speed, 'speed returns a defined value' );
    like( $speed, qr/^\d+\n$/, 'speed output is a number followed by newline' );
};

# ── single flag arg works ────────────────────────────────────────────

subtest 'single flag arg (not numeric, not special)' => sub {
    my ( $pty, $slave ) = fresh_pty();

    # Set echo, then pass single '-echo' arg
    IO::Stty::stty( $slave, 'echo' );
    IO::Stty::stty( $slave, '-echo' );
    my $t = get_termios($slave);
    ok( !( $t->getlflag & ECHO ), 'single -echo arg works' );
};

done_testing;
