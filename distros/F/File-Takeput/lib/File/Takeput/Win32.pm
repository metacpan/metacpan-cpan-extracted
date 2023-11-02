# File::Takeput::Win32.pm
# Used by the File::Takeput module.
# (c) 2023 Bjørn Hee
# Licensed under the Apache License, version 2.0
# https://www.apache.org/licenses/LICENSE-2.0.txt

package File::Takeput::Win32;

use strict;
use experimental qw(signatures);
use Exporter qw(import);

use Fcntl qw(LOCK_NB);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC usleep);

our @EXPORT = qw(flock_take);

our @EXPORT_OK = ();

# --------------------------------------------------------------------------- #
# Globals and defaults.

our $retry_pause = 50000; # Positive integer. Pause length in microseconds.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

1;

# --------------------------------------------------------------------------- #
# Exportable subs.

sub flock_take( $fh , $flag , $p ) {

    my $deadline = $p ? clock_gettime(CLOCK_MONOTONIC) + $p : 0;
    
    while (1) {
        return 1 if flock($fh , $flag|LOCK_NB);
        return undef if $deadline < clock_gettime(CLOCK_MONOTONIC);
        usleep($retry_pause);
        };
    };

# --------------------------------------------------------------------------- #

__END__
