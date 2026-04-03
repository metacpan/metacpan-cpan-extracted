#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use POSIX qw(:termios_h);

# We need a real tty for IO::Stty — a pty gives us one without needing
# an interactive terminal.
eval { require IO::Pty };
plan skip_all => 'IO::Pty required for functional tests' if $@;

use IO::Stty;

# ── helpers ────────────────────────────────────────────────────────────

sub fresh_pty {
    my $pty = IO::Pty->new or die "Cannot create pty: $!";
    my $slave = $pty->slave  or die "Cannot get slave: $!";
    return ($pty, $slave);
}

# Return a POSIX::Termios snapshot for $fh.
sub get_termios {
    my ($fh) = @_;
    my $t = POSIX::Termios->new;
    $t->getattr(fileno($fh)) or die "getattr: $!";
    return $t;
}

# ── 1. Basic flag toggling ────────────────────────────────────────────

subtest 'toggle echo flag' => sub {
    my ($pty, $slave) = fresh_pty();

    # enable echo, then verify
    IO::Stty::stty($slave, 'echo');
    my $t = get_termios($slave);
    ok($t->getlflag & ECHO, 'echo is set after stty echo');

    # disable echo
    IO::Stty::stty($slave, '-echo');
    $t = get_termios($slave);
    ok(!($t->getlflag & ECHO), 'echo is cleared after stty -echo');
};

subtest 'toggle multiple flags in one call' => sub {
    my ($pty, $slave) = fresh_pty();

    IO::Stty::stty($slave, '-echo', '-icanon', '-isig');
    my $t = get_termios($slave);
    ok(!($t->getlflag & ECHO),   '-echo applied');
    ok(!($t->getlflag & ICANON), '-icanon applied');
    ok(!($t->getlflag & ISIG),   '-isig applied');

    IO::Stty::stty($slave, 'echo', 'icanon', 'isig');
    $t = get_termios($slave);
    ok($t->getlflag & ECHO,   'echo re-enabled');
    ok($t->getlflag & ICANON, 'icanon re-enabled');
    ok($t->getlflag & ISIG,   'isig re-enabled');
};

subtest 'cflag settings (parenb, cs bits)' => sub {
    my ($pty, $slave) = fresh_pty();

    # Some pty drivers (Linux) silently ignore cs7/parenb since ptys don't
    # do real character framing.  Probe first, then test accordingly.
    IO::Stty::stty($slave, 'cs7');
    my $t = get_termios($slave);
    my $pty_supports_cs7 = (($t->getcflag & CS8) == CS7);

    SKIP: {
        skip 'pty driver does not honour cs7/parenb', 2 unless $pty_supports_cs7;
        IO::Stty::stty($slave, 'cs7', 'parenb');
        $t = get_termios($slave);
        is($t->getcflag & CS8, CS7, 'cs7 set correctly');
        ok($t->getcflag & PARENB, 'parenb enabled');
    }

    IO::Stty::stty($slave, 'cs8', '-parenb');
    $t = get_termios($slave);
    is($t->getcflag & CS8, CS8, 'cs8 set correctly');
    ok(!($t->getcflag & PARENB), 'parenb disabled');
};

subtest 'iflag settings (icrnl, ixon)' => sub {
    my ($pty, $slave) = fresh_pty();

    IO::Stty::stty($slave, '-icrnl', '-ixon');
    my $t = get_termios($slave);
    ok(!($t->getiflag & ICRNL), '-icrnl applied');
    ok(!($t->getiflag & IXON),  '-ixon applied');

    IO::Stty::stty($slave, 'icrnl', 'ixon');
    $t = get_termios($slave);
    ok($t->getiflag & ICRNL, 'icrnl re-enabled');
    ok($t->getiflag & IXON,  'ixon re-enabled');
};

subtest 'igncr toggle' => sub {
    my ($pty, $slave) = fresh_pty();

    IO::Stty::stty($slave, 'igncr');
    my $t = get_termios($slave);
    ok($t->getiflag & IGNCR, 'igncr set');

    IO::Stty::stty($slave, '-igncr');
    $t = get_termios($slave);
    ok(!($t->getiflag & IGNCR), 'igncr cleared');
};

subtest '-a output shows igncr' => sub {
    my ($pty, $slave) = fresh_pty();

    IO::Stty::stty($slave, 'igncr');
    my $output = IO::Stty::stty($slave, '-a');
    like($output, qr/(?<!\-)igncr/, '-a shows igncr when set');

    IO::Stty::stty($slave, '-igncr');
    $output = IO::Stty::stty($slave, '-a');
    like($output, qr/-igncr/, '-a shows -igncr when cleared');
};

subtest 'oflag (opost)' => sub {
    my ($pty, $slave) = fresh_pty();

    IO::Stty::stty($slave, '-opost');
    my $t = get_termios($slave);
    ok(!($t->getoflag & OPOST), '-opost applied');

    IO::Stty::stty($slave, 'opost');
    $t = get_termios($slave);
    ok($t->getoflag & OPOST, 'opost re-enabled');
};

# ── 2. -g / restore roundtrip ────────────────────────────────────────

subtest '-g roundtrip preserves settings' => sub {
    my ($pty, $slave) = fresh_pty();

    # Set a known non-default state (skip cs7 — may not stick on ptys)
    IO::Stty::stty($slave, '-echo', '-icanon', '-opost');

    # Capture with -g
    my $saved = IO::Stty::stty($slave, '-g');
    ok(defined $saved, '-g returns a value');
    like($saved, qr/^\d+:\d+:\d+:\d+:\d+:\d+/, '-g format is colon-separated integers');

    # Count fields: should be 17 (6 flags/speeds + 11 control chars)
    my @fields = split /:/, $saved;
    is(scalar @fields, 17, '-g output has 17 fields');

    # Now change things back
    IO::Stty::stty($slave, 'echo', 'icanon', 'opost');
    my $t = get_termios($slave);
    ok($t->getlflag & ECHO, 'echo is back on before restore');

    # Restore from -g output
    IO::Stty::stty($slave, $saved);
    $t = get_termios($slave);
    ok(!($t->getlflag & ECHO),   'echo still off after restore');
    ok(!($t->getlflag & ICANON), 'icanon still off after restore');
    ok(!($t->getoflag & OPOST),  'opost still off after restore');
};

# ── 3. -a human-readable output ──────────────────────────────────────

subtest '-a output format' => sub {
    my ($pty, $slave) = fresh_pty();
    my $output = IO::Stty::stty($slave, '-a');
    ok(defined $output, '-a returns output');
    like($output, qr/speed \d+ baud/, '-a contains speed line');
    like($output, qr/echo/,           '-a mentions echo');
    like($output, qr/icanon/,         '-a mentions icanon');
    like($output, qr/opost/,          '-a mentions opost');
    like($output, qr/cs\d/,           '-a shows character size');
    like($output, qr/intr\s*=/,       '-a shows intr control char');
};

# ── 4. Combination settings ──────────────────────────────────────────

subtest 'raw mode' => sub {
    my ($pty, $slave) = fresh_pty();
    IO::Stty::stty($slave, 'raw');
    my $t = get_termios($slave);

    # raw should clear these
    ok(!($t->getiflag & BRKINT), 'raw: -brkint');
    ok(!($t->getiflag & ICRNL),  'raw: -icrnl');
    ok(!($t->getiflag & IXON),   'raw: -ixon');
    ok(!($t->getoflag & OPOST),  'raw: -opost');
    ok(!($t->getlflag & ISIG),   'raw: -isig');
    ok(!($t->getlflag & ICANON), 'raw: -icanon');

    # min=1, time=0
    is($t->getcc(VMIN),  1, 'raw: min=1');
    is($t->getcc(VTIME), 0, 'raw: time=0');
};

subtest 'cooked mode (opposite of raw)' => sub {
    my ($pty, $slave) = fresh_pty();

    # Start from raw
    IO::Stty::stty($slave, 'raw');
    # Then go cooked
    IO::Stty::stty($slave, 'cooked');
    my $t = get_termios($slave);

    ok($t->getiflag & BRKINT, 'cooked: brkint set');
    ok($t->getiflag & ICRNL,  'cooked: icrnl set');
    ok($t->getiflag & IXON,   'cooked: ixon set');
    ok($t->getoflag & OPOST,  'cooked: opost set');
    ok($t->getlflag & ISIG,   'cooked: isig set');
    ok($t->getlflag & ICANON, 'cooked: icanon set');
};

subtest '-raw is same as cooked' => sub {
    my ($pty, $slave) = fresh_pty();
    IO::Stty::stty($slave, 'raw');
    IO::Stty::stty($slave, '-raw');
    my $t = get_termios($slave);
    ok($t->getlflag & ICANON, '-raw restores icanon');
    ok($t->getlflag & ISIG,   '-raw restores isig');
    ok($t->getoflag & OPOST,  '-raw restores opost');
};

subtest '-cooked is same as raw' => sub {
    my ($pty, $slave) = fresh_pty();
    IO::Stty::stty($slave, '-cooked');
    my $t = get_termios($slave);
    ok(!($t->getlflag & ICANON), '-cooked clears icanon');
    ok(!($t->getlflag & ISIG),   '-cooked clears isig');
    ok(!($t->getoflag & OPOST),  '-cooked clears opost');
};

subtest 'sane mode' => sub {
    my ($pty, $slave) = fresh_pty();

    # Scramble things first
    IO::Stty::stty($slave, 'raw', '-echo');

    # Apply sane
    IO::Stty::stty($slave, 'sane');
    my $t = get_termios($slave);

    ok($t->getlflag & ECHO,   'sane: echo enabled');
    ok($t->getlflag & ICANON, 'sane: icanon enabled');
    ok($t->getlflag & ISIG,   'sane: isig enabled');
    ok($t->getlflag & ECHOE,  'sane: echoe enabled');
    ok($t->getlflag & ECHOK,  'sane: echok enabled');
    ok($t->getiflag & ICRNL,  'sane: icrnl enabled');
    ok($t->getiflag & BRKINT, 'sane: brkint enabled');
    ok($t->getoflag & OPOST,  'sane: opost enabled');
    ok($t->getcflag & CREAD,  'sane: cread enabled');
    ok(!($t->getlflag & ECHONL), 'sane: -echonl');
    ok(!($t->getlflag & NOFLSH), 'sane: -noflsh');

    # sane sets specific control char values
    is($t->getcc(VINTR),  3,  'sane: intr=3 (^C)');
    is($t->getcc(VQUIT),  28, 'sane: quit=28 (^\\)');
    is($t->getcc(VERASE), 8,  'sane: erase=8 (^H)');
    is($t->getcc(VKILL),  21, 'sane: kill=21 (^U)');
    is($t->getcc(VEOF),   4,  'sane: eof=4 (^D)');
};

subtest 'pass8 / -pass8' => sub {
    my ($pty, $slave) = fresh_pty();

    IO::Stty::stty($slave, 'pass8');
    my $t = get_termios($slave);
    ok(!($t->getcflag & PARENB), 'pass8: -parenb');
    ok(!($t->getiflag & ISTRIP), 'pass8: -istrip');
    is($t->getcflag & CS8, CS8,  'pass8: cs8');

    IO::Stty::stty($slave, '-pass8');
    $t = get_termios($slave);
    # parenb and cs7 may not stick on pty drivers (no real char framing)
    ok($t->getiflag & ISTRIP,    '-pass8: istrip');
    SKIP: {
        skip 'pty driver does not honour parenb/cs7', 2
            unless ($t->getcflag & PARENB);
        ok($t->getcflag & PARENB,    '-pass8: parenb');
        is($t->getcflag & CS8, CS7,  '-pass8: cs7');
    }
};

subtest 'ek resets erase and kill' => sub {
    my ($pty, $slave) = fresh_pty();
    IO::Stty::stty($slave, 'erase', 42, 'kill', 42);
    IO::Stty::stty($slave, 'ek');
    my $t = get_termios($slave);
    is($t->getcc(VERASE), 8,  'ek: erase=8');
    is($t->getcc(VKILL),  21, 'ek: kill=21');
};

subtest 'dec combination' => sub {
    my ($pty, $slave) = fresh_pty();
    IO::Stty::stty($slave, 'dec');
    my $t = get_termios($slave);
    ok($t->getlflag & ECHOE, 'dec: echoe');
    ok($t->getlflag & ECHOK, 'dec: echok');
    is($t->getcc(VINTR),  3,   'dec: intr=3');
    is($t->getcc(VERASE), 127, 'dec: erase=127 (DEL)');
    is($t->getcc(VKILL),  21,  'dec: kill=21');
};

subtest 'crt combination' => sub {
    my ($pty, $slave) = fresh_pty();
    # Clear echoe/echok first so we can verify crt sets them
    IO::Stty::stty($slave, '-echoe', '-echok');
    my $t = get_termios($slave);
    ok(!($t->getlflag & ECHOE), 'echoe cleared before crt');

    IO::Stty::stty($slave, 'crt');
    $t = get_termios($slave);
    ok($t->getlflag & ECHOE, 'crt: echoe set');
    ok($t->getlflag & ECHOK, 'crt: echok set');
};

subtest 'crterase alias for echoe' => sub {
    my ($pty, $slave) = fresh_pty();

    IO::Stty::stty($slave, '-crterase');
    my $t = get_termios($slave);
    ok(!($t->getlflag & ECHOE), 'crterase clears ECHOE');

    IO::Stty::stty($slave, 'crterase');
    $t = get_termios($slave);
    ok($t->getlflag & ECHOE, 'crterase sets ECHOE');
};

# ── 5. Control character assignment ───────────────────────────────────

subtest 'set control chars by integer' => sub {
    my ($pty, $slave) = fresh_pty();
    IO::Stty::stty($slave, 'intr', 5, 'quit', 30, 'eof', 10);
    my $t = get_termios($slave);
    is($t->getcc(VINTR), 5,  'intr set to 5');
    is($t->getcc(VQUIT), 30, 'quit set to 30');
    is($t->getcc(VEOF),  10, 'eof set to 10');
};

subtest 'set control chars by hat notation' => sub {
    my ($pty, $slave) = fresh_pty();
    IO::Stty::stty($slave, 'intr', '^C', 'quit', '^\\', 'erase', '^?', 'eof', '^D');
    my $t = get_termios($slave);
    is($t->getcc(VINTR),  3,   'intr set to ^C (3)');
    is($t->getcc(VQUIT),  28,  'quit set to ^\\ (28)');
    is($t->getcc(VERASE), 127, 'erase set to ^? (127)');
    is($t->getcc(VEOF),   4,   'eof set to ^D (4)');
};

subtest 'disable control char with undef' => sub {
    # _POSIX_VDISABLE is the platform-specific value for "disabled"
    # (0 on Linux, 255 on macOS/BSD)
    my $VDISABLE = eval { POSIX::_POSIX_VDISABLE() };
    $VDISABLE = 0 unless defined $VDISABLE;

    my ($pty, $slave) = fresh_pty();
    IO::Stty::stty($slave, 'eol', 'undef');
    my $t = get_termios($slave);
    is($t->getcc(VEOL), $VDISABLE, 'eol disabled via undef (uses _POSIX_VDISABLE)');

    IO::Stty::stty($slave, 'eol', '^-');
    $t = get_termios($slave);
    is($t->getcc(VEOL), $VDISABLE, 'eol disabled via ^- (uses _POSIX_VDISABLE)');
};

subtest 'set min and time' => sub {
    my ($pty, $slave) = fresh_pty();
    IO::Stty::stty($slave, '-icanon', 'min', 5, 'time', 10);
    my $t = get_termios($slave);
    is($t->getcc(VMIN),  5,  'min set to 5');
    is($t->getcc(VTIME), 10, 'time set to 10');
};

subtest '-a output shows min and time' => sub {
    my ($pty, $slave) = fresh_pty();
    # min/time are only meaningful in non-canonical mode; on systems where
    # VEOF==VMIN (e.g. Solaris), setting min/time while ICANON is on would
    # overwrite the eof/eol slots instead.
    IO::Stty::stty($slave, '-icanon', 'min', 3, 'time', 7);
    my $output = IO::Stty::stty($slave, '-a');
    like($output, qr/min = 3/, '-a shows min value');
    like($output, qr/time = 7/, '-a shows time value');
};

# ── 6. Invalid parameter warning ─────────────────────────────────────

subtest 'invalid parameter produces warning' => sub {
    my ($pty, $slave) = fresh_pty();

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    IO::Stty::stty($slave, 'bogus_flag');

    is(scalar @warnings, 1, 'exactly one warning emitted');
    like($warnings[0], qr/invalid parameter 'bogus_flag'/, 'warning mentions the bad param');
};

subtest 'valid params mixed with invalid' => sub {
    my ($pty, $slave) = fresh_pty();

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    # echo should still be applied despite the bogus param
    IO::Stty::stty($slave, '-echo', 'nonsense', 'icanon');

    is(scalar @warnings, 1, 'one warning for nonsense');
    like($warnings[0], qr/invalid parameter 'nonsense'/, 'correct param in warning');

    my $t = get_termios($slave);
    ok(!($t->getlflag & ECHO), '-echo still applied despite invalid param');
    ok($t->getlflag & ICANON,  'icanon still applied despite invalid param');
};

# ── 7. Version output ────────────────────────────────────────────────

subtest 'version flag' => sub {
    my ($pty, $slave) = fresh_pty();
    my $v = IO::Stty::stty($slave, '-v');
    like($v, qr/\d+\.\d+/, '-v returns version string');
};

# ── 8. Non-tty returns undef ─────────────────────────────────────────

subtest 'non-tty handle returns undef' => sub {
    open my $fh, '<', '/dev/null' or die "open /dev/null: $!";
    my $result = IO::Stty::stty($fh, '-a');
    is($result, undef, 'non-tty returns undef');
    close $fh;
};

# ── 9. iexten flag ─────────────────────────────────────────────────────

subtest 'toggle iexten flag' => sub {
    my ($pty, $slave) = fresh_pty();

    IO::Stty::stty($slave, 'iexten');
    my $t = get_termios($slave);
    ok($t->getlflag & IEXTEN, 'iexten is set after stty iexten');

    IO::Stty::stty($slave, '-iexten');
    $t = get_termios($slave);
    ok(!($t->getlflag & IEXTEN), 'iexten is cleared after stty -iexten');
};

# ── 10. Return value on set operations ─────────────────────────────────

subtest 'stty returns true on successful set' => sub {
    my ($pty, $slave) = fresh_pty();

    my $result = IO::Stty::stty($slave, 'echo');
    ok($result, 'stty returns true value when setting flags');
};

# ── 11. iexten shown in -a output ─────────────────────────────────────

subtest 'iexten appears in -a output' => sub {
    my ($pty, $slave) = fresh_pty();

    my $output = IO::Stty::stty($slave, '-a');
    like($output, qr/-?iexten/, '-a output includes iexten');
};

done_testing;
