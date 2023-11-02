# File::Takeput::Unix.pm
# Used by the File::Takeput module.
# (c) 2023 Bjørn Hee
# Licensed under the Apache License, version 2.0
# https://www.apache.org/licenses/LICENSE-2.0.txt

package File::Takeput::Unix;

use strict;
use experimental qw(signatures);
use Exporter qw(import);

use Time::HiRes qw(ualarm);

our @EXPORT = qw(flock_take);

our @EXPORT_OK = ();

# --------------------------------------------------------------------------- #

1;

# --------------------------------------------------------------------------- #
# Exportable subs.

sub flock_take( $fh , $flag , $p ) {

    $p *= 1000000; # Seconds to microseconds.

    my $ret = undef;
    eval {
        local $SIG{ALRM} = sub { exit; };
        $@ = '';
        ualarm $p;
        exit if $@ ne '';
        $ret = flock($fh , $flag);
        ualarm 0; # Cancel timer.
        };
    return $ret;
    };

# --------------------------------------------------------------------------- #

__END__
