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

# ── cbreak / -cbreak ────────────────────────────────────────────────

subtest 'cbreak disables icanon' => sub {
    my ( $pty, $slave ) = fresh_pty();

    IO::Stty::stty( $slave, 'icanon' );
    my $t = get_termios($slave);
    ok( $t->getlflag & ICANON, 'icanon starts on' );

    IO::Stty::stty( $slave, 'cbreak' );
    $t = get_termios($slave);
    ok( !( $t->getlflag & ICANON ), 'cbreak clears icanon' );
};

subtest '-cbreak enables icanon' => sub {
    my ( $pty, $slave ) = fresh_pty();

    IO::Stty::stty( $slave, '-icanon' );
    my $t = get_termios($slave);
    ok( !( $t->getlflag & ICANON ), 'icanon starts off' );

    IO::Stty::stty( $slave, '-cbreak' );
    $t = get_termios($slave);
    ok( $t->getlflag & ICANON, '-cbreak sets icanon' );
};

# ── evenp / parity ──────────────────────────────────────────────────

subtest 'evenp sets parenb -parodd cs7' => sub {
    my ( $pty, $slave ) = fresh_pty();

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    IO::Stty::stty( $slave, 'evenp' );

    is( scalar @warnings, 0, 'no warnings' ) or diag "Got: @warnings";

    my $t = get_termios($slave);
    SKIP: {
        skip 'pty driver does not honour parenb/cs7', 3
            unless ( $t->getcflag & PARENB );
        ok( $t->getcflag & PARENB,          'evenp: parenb set' );
        ok( !( $t->getcflag & PARODD ),     'evenp: -parodd' );
        is( $t->getcflag & CS8, CS7,        'evenp: cs7' );
    }
};

subtest 'parity is same as evenp' => sub {
    my ( $pty, $slave ) = fresh_pty();

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    IO::Stty::stty( $slave, 'parity' );

    is( scalar @warnings, 0, 'no warnings' ) or diag "Got: @warnings";

    my $t = get_termios($slave);
    SKIP: {
        skip 'pty driver does not honour parenb/cs7', 3
            unless ( $t->getcflag & PARENB );
        ok( $t->getcflag & PARENB,          'parity: parenb set' );
        ok( !( $t->getcflag & PARODD ),     'parity: -parodd' );
        is( $t->getcflag & CS8, CS7,        'parity: cs7' );
    }
};

# ── oddp ────────────────────────────────────────────────────────────

subtest 'oddp sets parenb parodd cs7' => sub {
    my ( $pty, $slave ) = fresh_pty();

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    IO::Stty::stty( $slave, 'oddp' );

    is( scalar @warnings, 0, 'no warnings' ) or diag "Got: @warnings";

    my $t = get_termios($slave);
    SKIP: {
        skip 'pty driver does not honour parenb/parodd/cs7', 3
            unless ( $t->getcflag & PARENB );
        ok( $t->getcflag & PARENB,      'oddp: parenb set' );
        ok( $t->getcflag & PARODD,      'oddp: parodd set' );
        is( $t->getcflag & CS8, CS7,    'oddp: cs7' );
    }
};

# ── -evenp / -parity / -oddp ───────────────────────────────────────

subtest '-evenp clears parenb and sets cs8' => sub {
    my ( $pty, $slave ) = fresh_pty();

    IO::Stty::stty( $slave, '-evenp' );
    my $t = get_termios($slave);
    ok( !( $t->getcflag & PARENB ), '-evenp: -parenb' );
    is( $t->getcflag & CS8, CS8,    '-evenp: cs8' );
};

subtest '-parity clears parenb and sets cs8' => sub {
    my ( $pty, $slave ) = fresh_pty();

    IO::Stty::stty( $slave, '-parity' );
    my $t = get_termios($slave);
    ok( !( $t->getcflag & PARENB ), '-parity: -parenb' );
    is( $t->getcflag & CS8, CS8,    '-parity: cs8' );
};

subtest '-oddp clears parenb and sets cs8' => sub {
    my ( $pty, $slave ) = fresh_pty();

    IO::Stty::stty( $slave, '-oddp' );
    my $t = get_termios($slave);
    ok( !( $t->getcflag & PARENB ), '-oddp: -parenb' );
    is( $t->getcflag & CS8, CS8,    '-oddp: cs8' );
};

# ── litout / -litout ───────────────────────────────────────────────

subtest 'litout sets -parenb -istrip -opost cs8' => sub {
    my ( $pty, $slave ) = fresh_pty();

    IO::Stty::stty( $slave, 'litout' );
    my $t = get_termios($slave);
    ok( !( $t->getcflag & PARENB ),  'litout: -parenb' );
    ok( !( $t->getiflag & ISTRIP ),  'litout: -istrip' );
    ok( !( $t->getoflag & OPOST ),   'litout: -opost' );
    is( $t->getcflag & CS8, CS8,     'litout: cs8' );
};

subtest '-litout sets parenb istrip opost cs7' => sub {
    my ( $pty, $slave ) = fresh_pty();

    # Start from litout so we can verify the reverse
    IO::Stty::stty( $slave, 'litout' );

    IO::Stty::stty( $slave, '-litout' );
    my $t = get_termios($slave);

    ok( $t->getiflag & ISTRIP,   '-litout: istrip set' );
    ok( $t->getoflag & OPOST,    '-litout: opost set' );
    SKIP: {
        skip 'pty driver does not honour parenb/cs7', 2
            unless ( $t->getcflag & PARENB );
        ok( $t->getcflag & PARENB,       '-litout: parenb set' );
        is( $t->getcflag & CS8, CS7,     '-litout: cs7' );
    }
};

# ── no warnings for any of these ───────────────────────────────────

subtest 'no invalid parameter warnings for new combos' => sub {
    my @combos = qw( evenp parity oddp -evenp -parity -oddp cbreak -cbreak litout -litout );
    for my $combo (@combos) {
        my ( $pty, $slave ) = fresh_pty();
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };

        IO::Stty::stty( $slave, $combo );

        is( scalar @warnings, 0, "no warnings for '$combo'" )
            or diag "Got: @warnings";
    }
};

done_testing;
