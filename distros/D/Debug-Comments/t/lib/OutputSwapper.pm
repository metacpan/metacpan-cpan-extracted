use strict;
use warnings;

package OutputSwapper;

use autodie qw(open);

if ($ENV{FORCE_TTY}) {
    # Make Debug::Comments think STDERR is a TTY
    my $tty =
        -t STDERR ? *STDERR :
        -t STDIN  ? *STDIN  :
        -t STDOUT ? *STDOUT :
        undef;
    open($tty, '<', '/dev/tty')
        if !$tty && -c '/dev/tty';
    die "FORCE_TTY unable to find a TTY\n"
        unless $tty;
    local *STDERR = $tty;
    require Debug::Comments;
}

# Switch STDOUT, STDERR (to capture STDERR)
open(my $out, '>&', \*STDOUT);
open(my $err, '>&', \*STDERR);
open(STDOUT, '>&', $err);
open(STDERR, '>&', $out);

1;
