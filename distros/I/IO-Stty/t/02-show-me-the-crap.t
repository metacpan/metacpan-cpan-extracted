#!perl -T

use strict;
use warnings;

use Test::More;
use IO::Stty;
use POSIX ();

my ( $CS8, $B9600 );
eval { $CS8 = POSIX::CS8(); $B9600 = POSIX::B9600(); 1 }
    or plan skip_all => 'POSIX termios constants not available on this platform';

plan tests => 3;

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
);

my $output = IO::Stty::show_me_the_crap(
    $c_cflag, $c_iflag, $ispeed, $c_lflag, $c_oflag,
    $ospeed, \%cc,
);

like( $output, qr/^speed 9600 baud$/m, 'output contains speed line' );
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
