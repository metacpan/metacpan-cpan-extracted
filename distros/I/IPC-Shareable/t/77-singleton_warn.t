use warnings;
use strict;

use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

# singleton no exit notice
my ($proc, $warning);

{
    local $SIG{__WARN__} = sub {$warning = shift;};

    $proc = IPC::Shareable->singleton('LOCK', 1);

    is $proc, $$, "process ID $$ returned from singleton() ok on first call";

    $proc = -1;

    is $proc, -1, "\$proc set to -1 ok";

    $proc = IPC::Shareable->singleton('LOCK', 1);
}

END {
    is $proc, -1, "singleton() on second call doesn't return anything ok";
    like
        $warning,
        qr/exited due to exclusive shared memory collision/,
        "singleton() warns if warn is enabled";

    IPC::Shareable::_end;
    warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

    done_testing;
};
