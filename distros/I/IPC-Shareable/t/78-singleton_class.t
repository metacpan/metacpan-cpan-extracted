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

# bad param

my $ok = eval { IPC::Shareable::singleton(); 1 };
is $ok, undef, "singleton() croaks if no GLUE param sent in";
like $@, qr/GLUE parameter/, "...and error is sane";

# singleton no exit notice

my ($proc, $warning);

{
    local $SIG{__WARN__} = sub {$warning = shift;};

    $proc = IPC::Shareable::singleton('LOCK');

    is $proc, $$, "Class param is added if called in IPC::Shareable::singleton() format";

    $proc = -1;

    is $proc, -1, "\$proc set to -1 ok";

    $proc = IPC::Shareable::singleton('LOCK');
}

END {
    is $proc, -1, "singleton() on second call doesn't return anything ok";
    is $warning, undef, "singleton outputs no warnings by default";

    IPC::Shareable::_end;
    warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

    done_testing;
};
