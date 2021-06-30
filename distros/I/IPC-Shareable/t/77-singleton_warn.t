use warnings;
use strict;

use IPC::Shareable;
use Test::More;

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

    done_testing;
};
