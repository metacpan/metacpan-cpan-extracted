#!perl -T

use strict;
use warnings;

use Test::More;
use IO::Stty;
use POSIX ();

my ( $CS8, $B9600 );
eval { $CS8 = POSIX::CS8(); $B9600 = POSIX::B9600(); 1 }
    or plan skip_all => 'POSIX termios constants not available on this platform';

plan tests => 8;

# Build a minimal set of arguments for show_me_the_crap.
# Flags are all zero so every flag prints with '-' prefix.
my $c_cflag = $CS8;
my $c_iflag = 0;
my $c_lflag = 0;
my $c_oflag = 0;
my $ispeed  = $B9600;
my $ospeed  = $B9600;

my %cc = (
    INTR  => 3,    # ^C
    QUIT  => 28,   # ^\
    ERASE => 127,  # ^?
    KILL  => 21,   # ^U
    EOF   => 4,    # ^D
    EOL   => 0,    # <undef>
    START => 17,   # ^Q
    STOP  => 19,   # ^S
    SUSP  => 26,   # ^Z
    MIN   => 1,
    TIME  => 0,
);

my $output = IO::Stty::show_me_the_crap(
    $c_cflag, $c_iflag, $ispeed, $c_lflag, $c_oflag,
    $ospeed, \%cc,
);

like( $output, qr/^speed 9600 baud;$/m, 'output contains speed line' );
like(
    $output,
    qr/^intr = \^C; quit = \^\\; erase = \^\?; kill = \^U;$/m,
    'control chars line 1 uses hat notation',
);
like(
    $output,
    qr/^eof = \^D; eol = <undef>; start = \^Q; stop = \^S; susp = \^Z;$/m,
    'control chars line 2 uses hat notation',
);
like(
    $output,
    qr/^min = 1; time = 0;$/m,
    'min and time values displayed',
);

# Unknown ospeed falls back to raw numeric value (e.g. OpenBSD ptys)
{
    my $bogus_speed = 99999;
    my $out = IO::Stty::show_me_the_crap(
        $c_cflag, $c_iflag, $bogus_speed, $c_lflag, $c_oflag,
        $bogus_speed, \%cc,
    );
    like( $out, qr/^speed 99999 baud;$/m, 'unknown ospeed shows raw numeric value' );
}

# When ispeed differs from ospeed, ispeed is shown separately
{
    my $bogus_ispeed = 77777;
    my $out = IO::Stty::show_me_the_crap(
        $c_cflag, $c_iflag, $bogus_ispeed, $c_lflag, $c_oflag,
        $ospeed, \%cc,
    );
    like( $out, qr/ispeed 77777 baud;/m, 'unknown ispeed shows raw numeric value' );
}

# When ispeed differs but is a known baud rate, ispeed shows symbolic value
{
    my $B4800 = eval { POSIX::B4800() };
    SKIP: {
        skip 'B4800 not available', 1 unless defined $B4800;
        my $out = IO::Stty::show_me_the_crap(
            $c_cflag, $c_iflag, $B4800, $c_lflag, $c_oflag,
            $ospeed, \%cc,
        );
        like( $out, qr/ispeed 4800 baud;/m, 'known ispeed shows symbolic baud rate' );
    }
}

# When ispeed equals ospeed, no separate ispeed is shown
{
    my $out = IO::Stty::show_me_the_crap(
        $c_cflag, $c_iflag, $ospeed, $c_lflag, $c_oflag,
        $ospeed, \%cc,
    );
    unlike( $out, qr/ispeed/, 'ispeed not shown when equal to ospeed' );
}
